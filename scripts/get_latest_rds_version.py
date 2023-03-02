import os
import requests
import re

URL = 'https://docs.aws.amazon.com/AmazonRDS/latest/AuroraMySQLReleaseNotes/aurora-mysql-relnotes.rss'

if __name__ == '__main__':
    results = requests.get(URL).text
    versions = set(re.findall(r'3\.\d+\.\d+', results))
    versions = sorted(versions)
    versions.reverse()
    print(versions)

    version = versions[0]
    latest = f"8.0.mysql_aurora.{version}"

    if os.getenv("GITHUB_ACTIONS") == "true":
        print(f'::set-output name=LATEST_VERSION::{latest}')
    else:
        print(latest)
