#!/usr/bin/env python3

from abc import ABC
from abc import abstractmethod
from argparse import ArgumentParser, Namespace
from argparse import _SubParsersAction
import json
import sys
from typing import List, Optional
import os
from typing import TypeVar
from typing import Generic
from typing import Any
from dataclasses import dataclass

T = TypeVar("T")


@dataclass
class CompletedCommand(Generic[T]):
    success: bool = True
    data: Optional[T] = None

    @property
    def failure(self):
        return not self.success

    @property
    def exit_code(self):
        return 0 if self.success else 1


class CommandBase(ABC):
    command_name = "command_name"
    command_description = ""

    def __init__(self, subparser: _SubParsersAction) -> None:
        command_parser = subparser.add_parser(
            self.command_name,
            help=self.command_description,
            description=self.command_description,
        )
        command_parser.set_defaults(execute=self.__execute__)
        self._configure_parser(command_parser)

    @abstractmethod
    def _configure_parser(self, parser: ArgumentParser) -> None: ...

    @abstractmethod
    def do(self, *args, **kwargs) -> CompletedCommand[Any]: ...

    def __execute__(self, args: Namespace) -> int:
        completedCommand = None
        try:
            completedCommand = self.do(**vars(args))
        except Exception as e:
            completedCommand = CompletedCommand(success=False, data=e)
        if completedCommand.data is not None:
            print(completedCommand.data)
        return completedCommand.exit_code


class JsonTool(CommandBase):
    command_name = "jsonTool"
    command_description = (
        "This tool can pretty print json, retrieve item via json_path or search by key."
    )

    @staticmethod
    def __parse_path__(s: str) -> List[str]:
        path = s.strip()
        if len(path) == 0:
            return []
        delimeter = "][" if path[0] == "[" and path[-1] == "]" else "."
        return [s.strip() for s in path.strip("[]").split(delimeter) if s]

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
        current_key = (
            int(current_key) if isinstance(obj, (list, tuple)) else current_key
        )
        return cls.__json_traversal__(obj[current_key], remaining_keys)

    def _configure_parser(self, parser: ArgumentParser) -> None:
        parser.add_argument("-f", "--file")
        parser.add_argument("-p", "--json_path", type=self.__parse_path__)
        parser.add_argument("-s", "--search_key", type=str.lower)

    def do(self, file: str, json_path: List[str], search_key: str, *args, **kwargs) -> CompletedCommand[Any]:  # type: ignore  # noqa
        json_obj = {}
        if file:
            with open(file, "r") as f:
                json_obj = json.load(f)
        else:
            json_obj = json.load(sys.stdin)

        if (
            isinstance(json_obj, list)
            and len(json_obj) == 1
            and len(json_path)
            and json_path != "0"
        ):
            json_obj = json_obj[0]

        output = self.__json_traversal__(json_obj, json_path)

        if search_key:
            output = [
                {k: v}
                for k, v in self.__iterobj__(output)
                if search_key in k.lower() and v
            ]

        return CompletedCommand(
            data=json.dumps(output, sort_keys=True, indent=2, separators=(",", ": "))
        )


class FindUp(CommandBase):
    command_name = "findUp"
    command_description = "find item higher up in directory"

    def _configure_parser(self, parser: ArgumentParser) -> None:
        parser.add_argument("item", help="Item to find")
        parser.add_argument("--startpoint", help="Where to start search from.")
        parser.add_argument("-type", choices=("f", "d"))

    def do(self, item: str, startpoint: str = None, type: str = None, *args, **kwargs) -> CompletedCommand[str]:  # type: ignore  # noqa
        startpoint = (
            os.getcwd()
            if not startpoint
            else (
                startpoint if os.path.isdir(startpoint) else os.path.dirname(startpoint)
            )
        )

        extra_check = {
            "f": lambda _startingpoint: os.path.isfile(
                os.path.join(_startingpoint, item)
            ),
            "d": lambda _startingpoint: os.path.isdir(
                os.path.join(_startingpoint, item)
            ),
            None: lambda _: True,
        }[type]

        while startpoint != "/":
            if item in os.listdir(startpoint) and extra_check(startpoint):
                return CompletedCommand(data=startpoint)
            startpoint = os.path.dirname(startpoint)

        if item in os.listdir(startpoint):
            return CompletedCommand(data=startpoint)

        return CompletedCommand(success=False)


def main(argv=None):
    mainParser = ArgumentParser(description="Multi-Tool.")
    mainParser.set_defaults(execute=lambda _: mainParser.print_help())
    subparsers = mainParser.add_subparsers(dest="command")
    subparsers.required = True

    subCommands = CommandBase.__subclasses__()

    for subCommand in subCommands:
        subCommand(subparsers)

    args = mainParser.parse_args(argv)

    return args.execute(args)


if __name__ == "__main__":
    exit(main())
