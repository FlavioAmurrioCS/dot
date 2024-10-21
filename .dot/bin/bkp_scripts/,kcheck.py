#!/usr/bin/env python
from __future__ import print_function

import os
import sys
from datetime import datetime
from subprocess import CalledProcessError, check_output

INFO = "\033[1;37m"
ERROR = "\033[1;31m"
SUCCESS = "\033[1;32m"
WARNING = "\033[1;33m"


def color_log(color, msg):
    print(color + msg, file=sys.stderr)


class TicketExpiredException(Exception):
    pass


def parse_dates(line):
    def parse_date(date, time):
        return datetime.strptime(date + " " + time, "%m/%d/%Y %H:%M:%S")

    _, _, end_date, end_time, _ = line.split()
    return parse_date(end_date, end_time)


def kcheck():
    with open(os.devnull, "w") as devnull:
        output = check_output("klist", stderr=devnull).decode("utf-8")

    ticket = "krbtgt/AUTH.BLANK.COM@AUTH.BLANK.COM"
    match = next(line for line in output.splitlines() if ticket in line)

    end_date = parse_dates(match)
    current_date = datetime.now()

    delta = end_date - current_date
    if delta.total_seconds() < 0:
        raise TicketExpiredException
    color_log(WARNING, "Your kerberos ticket will expire in " + str(delta))


def main():
    try:
        return kcheck()
    except (CalledProcessError, IndexError, StopIteration, TicketExpiredException):
        color_log(
            WARNING,
            "No kerberos ticket.\n"
            + "Please renew your kerberos ticket on your Mac(ipa_kinit.sh).\n"
            + "May need to restart ssh/vscode connections.",
        )
        return 1


if __name__ == "__main__":
    exit(main())
