#!/usr/bin/env python3
from __future__ import print_function

import cgi
import os
import sys
import tempfile
import xml.etree.ElementTree as ET
from abc import ABC, abstractmethod
from contextlib import contextmanager, suppress
from dataclasses import dataclass
from os.path import abspath, basename, dirname, isdir, isfile, splitext
from subprocess import call, run
from typing import NamedTuple
from urllib.request import urlopen


################################################################################


@contextmanager
def touch_tmp_file():
    _, filename = tempfile.mkstemp()
    yield filename
    with suppress(FileNotFoundError):
        os.remove(filename)


def ensure_dir(path):
    with suppress(FileExistsError):
        os.makedirs(path)


def download_file(url, filename=None, overwrite=True):
    response = urlopen(url)
    if not filename:
        _, params = cgi.parse_header(response.headers.get("Content-Disposition", ""))
        filename = params.get("filename", url.split("/")[-1].split("?")[0])
    ensure_dir(dirname(abspath(filename)))
    if not os.path.isfile(filename):
        with open(filename, "wb") as f:
            f.write(response.read())
    return filename


class Logger:
    _INFO = "\033[1;37m"
    _ERROR = "\033[1;31m"
    _SUCCESS = "\033[1;32m"
    _WARNING = "\033[1;33m"

    def _color_log(self, color, msg):
        print(color + msg, file=sys.stderr)

    def info(self, msg):
        self._color_log(self._INFO, msg)

    def error(self, msg):
        self._color_log(self._ERROR, msg)

    def success(self, msg):
        self._color_log(self._SUCCESS, msg)

    def warn(self, msg):
        self._color_log(self._WARNING, msg)


################################################################################


class Config:
    """Base config."""

    USER_HOME = os.getenv("HOME")
    PROJECTS_HOME = os.path.join(USER_HOME, "projects")
    CODING_STANDARDS_HOME = os.path.join(PROJECTS_HOME, "coding-standards")
    ANALYZERS_HOME = "/tmp/analyzers"
    CHECKSTYLE_DOWNLOAD_LINK = "BLANK/checkstyle/checkstyle-8.39-all.jar"
    FINDBUGS_DOWNLOAD_LINK = "BLANK/ie-devtools/findbugs-3.0.1.tar.gz"


@dataclass
class Git:
    git_url: str
    project_path: str

    def __init__(self, git_url, project_path=None):
        self.git_url = git_url
        if not project_path:
            filename, _ = splitext(basename(self.git_url))
            self.project_path = os.path.join(Config.PROJECTS_HOME, filename)
        ensure_dir(basename(self.project_path))

    def clone(self):
        if not isdir(self.project_path):
            cmd = ["bash", "-c", f"git clone {self.git_url} {self.project_path}"]
            a = run(cmd, capture_output=True)
            print(a)


class StaticAnalyzerError(NamedTuple):
    filename: str = ""
    message: str = ""
    line: str = ""
    column: str = "0"
    severity: str = "low"
    source: str = ""

    def __repr__(self):
        return f"{self.filename}:{self.line} {self.message}"


class StaticAnalyzer(ABC):
    @abstractmethod
    def analyze(self, files):
        pass

    @abstractmethod
    def setup(self):
        pass


class Checkstyle(StaticAnalyzer):
    def __init__(self):
        self.coding_standards_git = Git("git@github.com")
        self.coding_standards_java = os.path.join(
            self.coding_standards_git.project_path, "java"
        )
        self.downloadlink = Config.CHECKSTYLE_DOWNLOAD_LINK
        self.jar_location = os.path.join(Config.ANALYZERS_HOME, "checkstyle.jar")
        header_txt = os.path.join(self.coding_standards_java, "header.txt")
        suppressions_xml = os.path.join(self.coding_standards_java, "suppressions.xml")
        checkstyle_xml = os.path.join(self.coding_standards_java, "checkstyle.xml")
        self.cmd = [
            "java",
            f"-Dcheckstyle.header.file={header_txt}",
            f"-Dcheckstyle.suppression.file={suppressions_xml}",
            "-jar",
            self.jar_location,
            "-f",
            "xml",
            "-c",
            checkstyle_xml,
        ]

    def analyze(self, files):
        with touch_tmp_file() as filename:
            cmd_arr = self.cmd + ["-o", filename] + files
            call(cmd_arr)

            tree = ET.parse(filename)
            root = tree.getroot()
            ret = []
            for file_elem in root.getchildren():
                filename = file_elem.attrib["name"]
                for error_elem in file_elem.getchildren():
                    ret.append(StaticAnalyzerError(filename, **error_elem.attrib))
            return ret

    def setup(self):
        self.coding_standards_git.clone()
        if not isfile(self.jar_location):
            download_file(self.downloadlink, self.jar_location)


class FindBugs(StaticAnalyzer):
    def __init__(self):
        self.downloadlink = Config.FINDBUGS_DOWNLOAD_LINK

    def setup(self):
        return super().setup()

    def analyze(self, files):
        return super().analyze(files)


class ProjectAnalyzer:
    def __init__(self, *static_analyzers, files=None, branch=None):
        self.static_analyzers = static_analyzers
        self.files = files or ProjectAnalyzer.git_diff_name_only(branch)

    @staticmethod
    def git_diff_name_only(branch=None):
        project_dir = "/Users/famurriomoya/projects/dotgov-tomcat"
        cmd_arr = [
            "git",
            f"--git-dir={project_dir}/.git",
            f"--work-tree={project_dir}",
            "diff",
            branch,
            "--name-only",
        ]
        if not branch:
            del cmd_arr[4]
        output = run(cmd_arr, capture_output=True).stdout.decode("utf-8")
        abs_file_paths = (os.path.join(project_dir, f) for f in output.splitlines())
        return [f for f in abs_file_paths if os.path.isfile(f)]

    def setup(self):
        for static_analyzer in self.static_analyzers:
            static_analyzer.setup()

    def analyze(self):
        ret = []
        for static_analyzer in self.static_analyzers:
            ret.extend(static_analyzer.analyze(self.files))
        return ret


def main():
    runner = ProjectAnalyzer(Checkstyle(), branch="master")
    runner.setup()
    static_analyzer_errors = runner.analyze()
    for foo in static_analyzer_errors:
        print(foo)


if __name__ == "__main__":
    exit(main())
