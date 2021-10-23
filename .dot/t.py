#!/usr/bin/env python3

from abc import ABC, abstractmethod
from abc import abstractclassmethod
import argparse
from argparse import ArgumentParser
from argparse import _SubParsersAction
from ast import parse


class CommandBase(ABC):

    def __init__(self, subparser: _SubParsersAction) -> None:
        super().__init__()
        command_parser = subparser.add_parser(self.command_name, help=self.command_description)
        command_parser.set_defaults(execute=self.execute)
        self._register_command(command_parser)

    @property
    @abstractmethod
    def command_name(self) -> str: ...

    @property
    @abstractmethod
    def command_description(self) -> str: ...

    @abstractmethod
    def _register_command(self, parser: ArgumentParser) -> None: ...

    @abstractmethod
    def execute(self, *args, **kwargs) -> int: ...


class Greeter(CommandBase):

    @property
    def command_name(self) -> str:
        return 'greeter'

    @property
    def command_description(self) -> str:
        return 'Will greet the argument'

    def _register_command(self, parser: ArgumentParser) -> None:
        parser.add_argument('name', help='Argument to be greeted')
        parser.add_argument('--lastname', help='LastName')

    def execute(self, name, lastname, *args, **kwargs) -> int:
        # name = args.name
        print(f'Hello {name} {lastname}')


def main(argv=None):
    mainParser = ArgumentParser()
    mainParser.set_defaults(execute=lambda _: mainParser.print_help())
    subparsers = mainParser.add_subparsers(dest='command')
    subparsers.required = True

    subCommands = CommandBase.__subclasses__()

    for subCommand in subCommands:
        subCommand(subparsers)

    args = mainParser.parse_args(argv)

    return args.execute(**vars(args))


if __name__ == "__main__":
    exit(main())
