#!/usr/bin/env python
import re
import cgi
import time

from multiprocessing.pool import ThreadPool
from subprocess import check_output
from functools import wraps
from os.path import isfile
from contextlib import contextmanager
import sys
import os
import tarfile

if sys.version_info > (3, 0):
    from urllib.request import urlopen
else:
    from urllib2 import urlopen


@contextmanager
def suppress(error=Exception):
    try:
        yield
    except error:
        pass


repos = (
    "sharkdp/bat",
    "BurntSushi/ripgrep",
    "direnv/direnv",
    "docker/compose",
    "junegunn/fzf",
    "hadolint/hadolint",
    "jesseduffield/lazydocker",
    "jesseduffield/lazygit",
    "jesseduffield/lazynpm",
    "sharkdp/fd",
    "koalaman/shellcheck",
    "mvdan/sh",
    "isacikgoz/tldr",
)

USER_HOME = os.environ.get("HOME")
DOWNLOAD_LOCATION = os.path.join(USER_HOME, "bin_downloads")

with suppress(OSError):
    os.makedirs(DOWNLOAD_LOCATION)


def download_file(url, filename=None, download_path=DOWNLOAD_LOCATION):
    response = urlopen(url)
    if not filename:
        _, params = cgi.parse_header(response.headers.get("Content-Disposition", ""))
        filename = params.get("filename", url.split("/")[-1].split("?")[0])
    abs_filepath = os.path.join(download_path, filename)
    if not isfile(abs_filepath):
        with open(abs_filepath, "wb") as f:
            f.write(response.read())
    file_type = (
        str(check_output(["file", "-b", abs_filepath]).decode("utf-8"))
        .strip()
        .split(",")[0]
    )
    if "compressed" in file_type.lower() and tarfile.is_tarfile(abs_filepath):
        with tarfile.open(abs_filepath) as tar_file:
            tar_file.extractall(download_path)
    return (abs_filepath, file_type)


def download_bin(project):
    download_url = "https://github.com/{}/releases/latest".format(project)
    search_string = "/{}/releases/download".format(project)
    response = urlopen(download_url)
    lines = str(response.read()).split('"')
    download_lunks = [
        "https://github.com{}".format(line) for line in lines if search_string in line
    ]
    download_links = [
        line
        for line in download_lunks
        if re.search("(darwin|apple)", line.lower())
        and not re.search("(\.sha|32)", line.split("/")[-1].lower())
    ]
    download_link = download_links[0]
    return download_file(download_link)


def timing(f):
    @wraps(f)
    def wrap(*args, **kw):
        ts = time.time()
        result = f(*args, **kw)
        te = time.time()
        print("func:%r args:[%r, %r] took: %2.4f sec" % (f.__name__, args, kw, te - ts))
        return result

    return wrap


@timing
def main():
    results = ThreadPool(5).imap_unordered(download_bin, repos)
    # results = (download_bin(repo) for repo in repos)

    for result in sorted(results, key=lambda x: "compressed" in x[1].lower()):
        print(result)


if __name__ == "__main__":
    exit(main())
