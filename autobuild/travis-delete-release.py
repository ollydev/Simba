import os
import json

def git(args):
    os.system("curl --silent -H 'Authorization: token " + os.environ['GITHUB_API_KEY'] + "' " + args + " | tee >/dev/null")
	
git('-o releases https://api.github.com/repos/' + os.environ['REPO_PATH'] + '/releases')

with open('releases', 'r') as f:
    releases = json.loads(f.read())

# release
for release in releases:
    if release['name'] == os.environ['RELEASE_NAME']:
    	git('-X DELETE https://api.github.com/repos/' + os.environ['REPO_PATH'] + '/releases/' + str(release['id']))

# tag
git('-X DELETE https://api.github.com/repos/' + os.environ['REPO_PATH'] + '/git/refs/tags/' + os.environ['TAG_NAME'])