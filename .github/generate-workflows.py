#!/usr/bin/env python3
import os
import json
import itertools


def chunked_iter(iterable, size):
    it = iter(iterable)
    while True:
        chunk = tuple(itertools.islice(it, size))
        if not chunk:
            break
        yield chunk


def main():
    current_dir = os.path.abspath(os.path.dirname(__file__))
    tpl_file = os.path.join(current_dir, 'workflow.yml.template')
    with open(tpl_file, encoding='utf-8') as f:
        template = f.read()
    targets_file = os.path.join(current_dir, 'targets.json')
    with open(targets_file) as f:
        all_targets = json.load(f)
    for targets in chunked_iter(all_targets, 2):
        target_name = ','.join(x['IMAGE_TAG'] for x in targets)
        target_env = json.dumps(targets)
        content = template.replace('#TARGETNAME#', target_name).replace('#ENV#', target_env)
        workflow_file = os.path.join(current_dir, 'workflows', f'{target_name.replace(",", "_")}.yml')
        with open(workflow_file, 'w', encoding='utf-8') as f:
            f.write(content)


if __name__ == '__main__':
    main()
