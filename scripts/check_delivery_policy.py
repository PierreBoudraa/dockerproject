#!/usr/bin/env python3
"""Exigences publiques de securite pour le workflow, compose.yaml et le Dockerfile."""
import argparse, re, sys
from pathlib import Path

REQUIRED_JOBS = ["validate", "build-publish", "supply-chain"]

def strip(line):
    return re.sub(r'(^|\s)#.*$', '', line)

def check_workflow(text):
    errs = []
    top = job = None
    jobs, jobs_if = [], {}
    checkout = persist = 0
    has_perm = False
    body = []
    for n, raw in enumerate(text.splitlines(), 1):
        l = strip(raw)
        body.append(l)
        m = re.match(r'^([A-Za-z_-]+):', l)
        if m:
            top, job = m.group(1), None
            has_perm = has_perm or top == 'permissions'
        if top == 'jobs':
            mj = re.match(r'^  ([A-Za-z0-9_-]+):\s*$', l)
            if mj:
                job = mj.group(1); jobs.append(job)
            if job and l.startswith('    if:'):
                jobs_if[job] = l
        mu = re.match(r'^\s*(?:-\s*)?uses:\s*(\S+)', l)
        if mu:
            v = mu.group(1)
            if not v.startswith('./') and not re.search(r'@[0-9a-f]{40}$', v):
                errs.append(f'R1 ligne {n}: action non epinglee sur un SHA complet: {v}')
            if v.startswith('actions/checkout@'):
                checkout += 1
        if re.search(r'persist-credentials:\s*false', l):
            persist += 1
        if re.search(r':\s*write-all\b', l):
            errs.append(f'R2 ligne {n}: permissions write-all')
        mw = re.match(r'^\s+([a-z-]+):\s*write\s*$', l)
        if mw:
            if top == 'permissions':
                errs.append(f'R2 ligne {n}: permission d\'ecriture globale ({mw.group(1)})')
            elif not (mw.group(1) == 'packages' and job == 'build-publish'):
                errs.append(f'R3 ligne {n}: ecriture {mw.group(1)} hors du job de publication (job={job})')
    if not has_perm:
        errs.append('R2: bloc permissions de premier niveau absent')
    if checkout > persist:
        errs.append('R5: un checkout sans persist-credentials: false')
    joined = "\n".join(body)
    if re.search(r'pull_request_target', joined):
        errs.append('R4: pull_request_target interdit')
    if re.search(r'(?i)\bssh\b|ssh-action|ssh_key|known_hosts|appleboy', joined):
        errs.append('R4: acces a un hote distant interdit dans la CI')
    for s in sorted(set(re.findall(r'secrets\.([A-Za-z0-9_]+)', joined))):
        if s != 'GITHUB_TOKEN':
            errs.append(f'R4: secret interdit: {s}')
    if re.search(r':latest\b', joined):
        errs.append('R4: tag :latest interdit')
    if re.search(r'docker[ -]compose\b[^\n]*\bup\b', joined):
        errs.append('R4: deploiement (compose up) interdit dans la CI')
    for j in REQUIRED_JOBS:
        if j not in jobs:
            errs.append(f'R6: job requis absent: {j}')
    cond = jobs_if.get('build-publish', '')
    if "github.event_name == 'push'" not in cond or 'refs/heads/coursework' not in cond:
        errs.append("R6: build-publish doit etre limite a un push sur refs/heads/coursework")
    if '${{ github.sha }}' not in joined:
        errs.append('R6: le SHA Git complet doit etre utilise')
    return errs

def check_compose(text):
    errs = []
    in_services = False; svc = None; in_ports = False
    for n, raw in enumerate(text.splitlines(), 1):
        l = strip(raw)
        if re.match(r'^services:\s*$', l):
            in_services = True; continue
        if re.match(r'^\S', l):
            in_services = False
        ms = re.match(r'^  ([A-Za-z0-9_-]+):\s*$', l)
        if in_services and ms:
            svc = ms.group(1); in_ports = False
        if re.match(r'^\s+ports:\s*$', l):
            in_ports = True
            if svc != 'proxy':
                errs.append(f'C1 ligne {n}: seul proxy peut publier un port (service={svc})')
            continue
        if in_ports:
            me = re.match(r'^\s*-\s*["\']?([^"\'\s]+)', l)
            if me:
                if not me.group(1).startswith('127.0.0.1:'):
                    errs.append(f'C1 ligne {n}: publication hors boucle locale: {me.group(1)}')
            elif l.strip():
                in_ports = False
        if re.search(r'docker\.sock|privileged:\s*true|network_mode:\s*["\']?host|pid:\s*["\']?host|cap_add:', l):
            errs.append(f'C2 ligne {n}: option dangereuse: {l.strip()}')
    return errs

def check_dockerfile(text):
    users = re.findall(r'(?im)^USER\s+(\S+)', text)
    if not users:
        return ['D1: aucune instruction USER']
    if users[-1].split(':')[0] in ('root', '0'):
        return [f'D1: utilisateur final root ({users[-1]})']
    return []

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--workflow', default='.github/workflows/container-delivery.yml')
    ap.add_argument('--compose', default='compose.yaml')
    ap.add_argument('--dockerfile', default='Dockerfile')
    a = ap.parse_args()
    errs = (check_workflow(Path(a.workflow).read_text())
            + check_compose(Path(a.compose).read_text())
            + check_dockerfile(Path(a.dockerfile).read_text()))
    for e in errs:
        print('FAIL', e, file=sys.stderr)
    if errs:
        return 1
    print('PASS: workflow, compose.yaml et Dockerfile respectent les exigences publiques')
    return 0

if __name__ == '__main__':
    sys.exit(main())
