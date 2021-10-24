#!/usr/bin/env python3

from abc import ABC
from abc import abstractmethod
from argparse import ArgumentParser
from argparse import _SubParsersAction
import json
import sys
from typing import List
import os

SUCCESS_EXIT_CODE = 0
FAILURE_EXIT_CODE = 1


class CommandBase(ABC):

    def __init__(self, subparser: _SubParsersAction) -> None:
        super().__init__()
        command_parser = subparser.add_parser(
            self.command_name, help=self.command_description, description=self.command_description)
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


class JsonTool(CommandBase):

    @property
    def command_name(self) -> str:
        return 'jsonTool'

    @property
    def command_description(self) -> str:
        return 'This tool can pretty print json, retrieve item via json_path or search by key.'

    @staticmethod
    def __parse_path__(s: str) -> List[str]:
        path = s.strip()
        if len(path) == 0:
            return []
        delimeter = '][' if path[0] == '[' and path[-1] == ']' else '.'
        return [s.strip() for s in path.strip('[]').split(delimeter) if s]

    @classmethod
    def __iterobj__(cls, obj):  # noqa: C901
        if isinstance(obj, list):
            for i in (o for o in obj if isinstance(o, (list, tuple, dict))):
                for k, v in cls.__iterobj__(i):
                    yield (k, v)
        if isinstance(obj, dict):
            for k, v in obj.items():
                yield (k, v)
                if isinstance(v, (list, tuple, dict)):
                    for key, value in cls.__iterobj__(v):
                        yield (key, value)

    @classmethod
    def __json_traversal__(cls, obj, path):
        if not path:
            return obj
        if not isinstance(obj, (list, dict, tuple)):
            raise KeyError
        current_key, remaining_keys = path[0], path[1:]
        current_key = int(current_key) if isinstance(obj, (list, tuple)) else current_key
        return cls.__json_traversal__(obj[current_key], remaining_keys)

    def _register_command(self, parser: ArgumentParser) -> None:
        parser.add_argument('-f', '--file')
        parser.add_argument('-p', '--json_path', type=self.__parse_path__)
        parser.add_argument('-s', '--search_key', type=str.lower)

    def execute(self, file: str, json_path: List[str], search_key: str, *args, **kwargs) -> int:
        json_obj = {}
        if file:
            with open(file, 'r') as f:
                json_obj = json.load(f)
        else:
            json_obj = json.load(sys.stdin)

        if isinstance(json_obj, list) and len(json_obj) == 1 and len(json_path) and json_path != '0':
            json_obj = json_obj[0]

        output = self.__json_traversal__(json_obj, json_path)

        if search_key:
            output = [{k: v} for k, v in self.__iterobj__(output) if search_key in k.lower() and v]

        json.dump(output, sys.stdout, sort_keys=True, indent=2, separators=(',', ': '))


class FindUp(CommandBase):

    @property
    def command_name(self) -> str:
        return 'findUp'

    @property
    def command_description(self) -> str:
        return 'find item higher up in directory'

    def _register_command(self, parser: ArgumentParser) -> None:
        parser.add_argument('item', help='Item to find')
        parser.add_argument('--startpoint', help='Where to start search from.')

    @staticmethod
    def do(item: str, startpoint: str = None) -> str:
        startpoint = (os.getcwd() if not startpoint
                      else (startpoint if os.path.isdir(startpoint)
                            else os.path.dirname(startpoint)))

        while startpoint != '/':
            if item in os.listdir(startpoint):
                return startpoint
            startpoint = os.path.dirname(startpoint)

        if item in os.listdir(startpoint):
            return startpoint

        return None

    def execute(self, item: str, startpoint: str = None, *args, **kwargs) -> int:
        result = self.do(item, startpoint)

        if not result:
            return FAILURE_EXIT_CODE

        print(result)
        return SUCCESS_EXIT_CODE


def main(argv=None):
    mainParser = ArgumentParser(
        description='Multi-Tool.'
        )
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
