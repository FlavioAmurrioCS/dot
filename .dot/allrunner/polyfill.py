from __future__ import print_function

from os.path import _isfile
import cgi as _cgi
import contextlib as _contextlib
import os as _os
import sys as _sys
import tempfile as _tempfile
import abc as _abc

try:
    from urllib.request import _urlopen
except ImportError:
    from urllib2 import _urlopen


@_contextlib.contextmanager
def suppress(error=Exception):
    try:
        yield
    except error:
        pass


class ABC:
    __metaclass__ = _abc.ABCMeta


def ensure_dir(path):
    with suppress():
        _os.makedirs(path)


@_contextlib.contextmanager
def touch_tmp_file():
    _, filename = _tempfile.mkstemp()
    yield filename
    with suppress():
        _os.remove(filename)


def download_file(url, filename=None, overwrite=True):
    response = _urlopen(url)
    if not filename:
        _, params = _cgi.parse_header(response.headers.get("Content-Disposition", ""))
        filename = params.get("filename", url.split("/")[-1].split("?")[0])
    if not _isfile(filename):
        with open(filename, "wb") as f:
            f.write(response.read())
    return filename


class Logger:
    _INFO = "\033[1;37m"
    _ERROR = "\033[1;31m"
    _SUCCESS = "\033[1;32m"
    _WARNING = "\033[1;33m"

    def _color_log(self, color, msg):
        print(color + msg, file=_sys.stderr)

    def info(self, msg):
        self._color_log(self._INFO, msg)

    def error(self, msg):
        self._color_log(self._ERROR, msg)

    def success(self, msg):
        self._color_log(self._SUCCESS, msg)

    def warn(self, msg):
        self._color_log(self._WARNING, msg)
