#!/usr/bin/env python3
"""Tempo v4 client. Credentials stay in the local owner-only .env file."""
import argparse
import base64
import datetime
import json
import os
from pathlib import Path
import re
import stat
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


class Client:
    def __init__(self, config):
        path = Path(config).expanduser()
        if stat.S_IMODE(path.stat().st_mode) & 0o077:
            raise ValueError('Credential file must have owner-only permissions (chmod 600).')
        self.cfg = {}
        for line in path.read_text().splitlines():
            if '=' in line and not line.lstrip().startswith('#'):
                key, value = line.split('=', 1)
                self.cfg[key.strip()] = value.strip().strip('\"\'')
        self.base = self.cfg['TEMPO_API_BASE'].rstrip('/')
        if not self.base.endswith('/4'):
            self.base += '/4'
        self.jira = self.cfg['JIRA_BASE'].rstrip('/')
        if urllib.parse.urlparse(self.base).hostname not in {'api.tempo.io', 'api.eu.tempo.io', 'api.us.tempo.io'}:
            raise ValueError('Unexpected Tempo host')
        jira_url = urllib.parse.urlparse(self.jira)
        if jira_url.scheme != 'https' or not (jira_url.hostname or '').endswith('.atlassian.net') or jira_url.path:
            raise ValueError('JIRA_BASE must be https://<site>.atlassian.net')
        self.last_request = 0

    def request(self, path, method='GET', body=None, jira=False):
        base = self.jira if jira else self.base
        url = path if path.startswith('https://') else base + path
        if urllib.parse.urlparse(url).netloc != urllib.parse.urlparse(base).netloc or not url.startswith(base + '/'):
            raise ValueError('Refusing credentials outside the configured API base')
        auth = 'Bearer ' + self.cfg['TEMPO_TOKEN']
        if jira:
            auth = 'Basic ' + base64.b64encode((self.cfg['JIRA_EMAIL'] + ':' + self.cfg['JIRA_TOKEN']).encode()).decode()
        time.sleep(max(0, 1 - (time.monotonic() - self.last_request)))
        req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                     headers={'Authorization': auth, 'Accept': 'application/json', 'Content-Type': 'application/json'})
        self.last_request = time.monotonic()
        # Never retry writes: a timeout may follow a successful commit.
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)

    def list(self, path):
        result = []
        while path:
            page = self.request(path)
            result.extend(page['results'])
            path = page.get('metadata', {}).get('next')
        return result

    def worklogs(self, start, end):
        query = urllib.parse.urlencode({'from': start, 'to': end, 'limit': 1000})
        return self.list('/worklogs/user/' + urllib.parse.quote(self.cfg['TEMPO_ACCOUNT_ID'], safe='') + '?' + query)

    def save(self, filename, update_id):
        payload = json.loads(Path(filename).read_text())
        if payload.get('authorAccountId', self.cfg['TEMPO_ACCOUNT_ID']) != self.cfg['TEMPO_ACCOUNT_ID']:
            raise ValueError('This helper writes only the configured user’s time')
        payload['authorAccountId'] = self.cfg['TEMPO_ACCOUNT_ID']
        previous = None
        if update_id:
            previous = self.request('/worklogs/' + str(update_id))
            if previous['author']['accountId'] != self.cfg['TEMPO_ACCOUNT_ID']:
                raise ValueError('Worklog belongs to another user')
            preserved = {key: previous[key] for key in ['startDate', 'startTime', 'description', 'timeSpentSeconds', 'billableSeconds'] if key in previous}
            preserved['attributes'] = previous.get('attributes', {}).get('values', [])
            preserved.update(payload)
            payload = preserved
        allowed = {'authorAccountId', 'startDate', 'startTime', 'description', 'timeSpentSeconds', 'billableSeconds', 'attributes'}
        if not update_id:
            allowed.add('issueId')
        if set(payload) - allowed:
            raise ValueError('Unsupported fields; updates preserve the issue and never change estimates or approvals')
        datetime.date.fromisoformat(payload['startDate'])
        if not re.fullmatch(r'\d{2}:\d{2}:\d{2}', payload.get('startTime', '')):
            raise ValueError('Supply startTime as HH:MM:SS')
        datetime.time.fromisoformat(payload['startTime'])
        seconds = payload['timeSpentSeconds']
        if type(seconds) is not int or seconds <= 0 or seconds % 60:
            raise ValueError('timeSpentSeconds must be a positive whole number of minutes')
        if not payload.get('description', '').strip():
            raise ValueError('Description is required')
        if not any(a.get('key') == '_Account_' and a.get('value') for a in payload.get('attributes', [])):
            raise ValueError('Supply the verified _Account_ work attribute')
        if not update_id:
            if type(payload.get('issueId')) is not int or payload['issueId'] <= 0:
                raise ValueError('Supply Jira numeric issueId')
            rows = self.worklogs(payload['startDate'], payload['startDate'])
            for row in rows:
                if row['issue']['id'] == payload['issueId'] and (row.get('startTime') == payload['startTime'] or row.get('description') == payload['description']):
                    raise ValueError('Possible duplicate; reconcile existing worklog ' + str(row['tempoWorklogId']))
        saved = self.request('/worklogs/' + str(update_id) if update_id else '/worklogs', 'PUT' if update_id else 'POST', payload)
        verified = self.request('/worklogs/' + str(saved['tempoWorklogId']))
        for key in ['startDate', 'startTime', 'description', 'timeSpentSeconds']:
            if verified.get(key) != payload[key]:
                raise RuntimeError('Saved worklog verification mismatch: ' + key)
        if verified['author']['accountId'] != payload['authorAccountId']:
            raise RuntimeError('Saved author mismatch')
        expected_issue = previous['issue']['id'] if previous else payload['issueId']
        if verified['issue']['id'] != expected_issue:
            raise RuntimeError('Saved issue mismatch')
        actual = {a['key']: a['value'] for a in verified.get('attributes', {}).get('values', [])}
        if any(actual.get(a['key']) != a['value'] for a in payload['attributes']):
            raise RuntimeError('Saved account/attributes mismatch')
        return verified


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='~/.config/tempo/.env')
    sub = parser.add_subparsers(dest='command', required=True)
    logs = sub.add_parser('worklogs')
    logs.add_argument('start'); logs.add_argument('end')
    sub.add_parser('accounts'); sub.add_parser('attributes'); sub.add_parser('identity')
    issue = sub.add_parser('issue'); issue.add_argument('key')
    save = sub.add_parser('save', help='Write a reviewed JSON payload, then verify by GET')
    save.add_argument('payload'); save.add_argument('--update', type=int)
    args = parser.parse_args()
    client = Client(args.config)
    if args.command == 'worklogs':
        data = client.worklogs(args.start, args.end)
    elif args.command == 'accounts':
        data = client.list('/accounts?limit=1000')
    elif args.command == 'attributes':
        data = client.list('/work-attributes')
    elif args.command == 'identity':
        identity = client.request('/rest/api/3/myself', jira=True)
        data = {'configuredUserMatchesJira': identity['accountId'] == client.cfg['TEMPO_ACCOUNT_ID'],
                'jiraProfileTimeZone': identity.get('timeZone')}
    elif args.command == 'issue':
        data = client.request('/rest/api/3/issue/' + urllib.parse.quote(args.key, safe='') + '?fields=summary,status,created', jira=True)
        data = {'id': int(data['id']), 'key': data['key'], 'summary': data['fields']['summary'],
                'status': data['fields']['status']['name'], 'created': data['fields']['created']}
    else:
        data = client.save(args.payload, args.update)
    print(json.dumps(data, indent=2))


if __name__ == '__main__':
    try:
        main()
    except urllib.error.HTTPError as error:
        sys.exit('API returned HTTP ' + str(error.code) + '. Check permissions/expiry; do not blindly retry writes.')
    except urllib.error.URLError:
        sys.exit('API connection failed. For a write, reconcile live worklogs before retrying.')
    except (ValueError, KeyError, RuntimeError, OSError) as error:
        sys.exit(str(error))
