
import os
import requests
import re

from packaging import version


URL = 'https://docs.aws.amazon.com/eks/latest/userguide/doc-history.rss'


if __name__ == '__main__':
    results = requests.get(URL).text
    versions = set(v.strip('kubernetes-') for v in re.findall(r'kubernetes-1\.\d+', results))

    versions = sorted(versions, key=version.Version)
    versions.reverse()
    print(versions)

    latest = versions[0]

    if os.getenv("GITHUB_ACTIONS") == "true":
        print(f'::set-output name=LATEST_VERSION::{latest}')
    else:
        print(latest)
