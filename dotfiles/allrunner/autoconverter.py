from typing import NamedTuple
from functools import wraps
from inspect import getfullargspec
from contextlib import suppress


def auto_convert_args(func):
    """
    This is a decorator which will auto convert arguments based on functions's typing annotation."""

    fullArgSpec = getfullargspec(func)

    var_names = (fullArgSpec.args[1:]  # if first var_name is named _cls, then we must omit it
                 if fullArgSpec.args and fullArgSpec.args[0] == '_cls'
                 else fullArgSpec.args)

    spec_annotations = fullArgSpec.annotations  # annotation identified by inspect
    defaults = fullArgSpec.defaults or ()  # tuple of the kwargs values
    default_kwargs = dict(zip(reversed(var_names), reversed(defaults)))

    # Maybe the kwargs may not be annotatated, here we determined those types based on the default values.
    defaults_annotations = {k: type(v) for k, v in default_kwargs.items()}

    annotations = {**spec_annotations, **defaults_annotations}

    def convert_value(value, type_class):
        """
        Will check if value is an instance of type_var.
        If it is, it will return the same value,
        else it will attempt the conversion.
        """
        if type(type_class) == type(int):  # checking if type_class is a primitive
            return value if isinstance(value, type_class) else type_class(value)
        elif hasattr(type_class, '__origin__'):  # checking if type_class is a wrapper over a primitive
            return value if isinstance(value, type_class.__origin__) else type_class.__origin__(value)
        elif hasattr(type_class, '__constraints__'):  # checking if type_class is an Union
            return value if isinstance(value, type_class.__constraints__) else type_class.__constraints__[-1](value)
        return value

    @wraps(func)
    def wrapped(*args, **kwargs):
        # Combined args and kwargs into a single dict.
        c_kwargs = {**default_kwargs, **dict(zip(var_names, args)), **kwargs}

        # If there is an annotation for an arg, attempt the conversion.
        for var_name, value in c_kwargs.items():
            if var_name in annotations:
                with suppress(BaseException):  # If conversion fails, just ignore it.
                    c_kwargs[var_name] = convert_value(value, annotations[var_name])
        return func(**c_kwargs)
    return wrapped

def print_dict_type_table(dct):
    print(f"{'var_name':>12} | {'val_type':15} | value")
    print('-' * 60)
    for var_name, value in dct.items():
        val_type = str(type(value))
        print(f"{var_name:>12} | {val_type:15} | {value!r}")

@auto_convert_args
def example(timeout: str, time: list, sleep: int, boo: str, baz=2, foo=3):
    args = locals()
    print_dict_type_table(args)


example(1, '23', "3", '4', baz='34', foo=212)
#     var_name | val_type        | value
# ------------------------------------------------------------
#      timeout | <class 'str'>   | '1'
#         time | <class 'list'>  | ['2', '3']
#        sleep | <class 'int'>   | 3
#          boo | <class 'str'>   | '4'
#          baz | <class 'int'>   | 34
#          foo | <class 'int'>   | 212
print()
print('=' * 100)
print()

class AppInfo(NamedTuple):
    application: str
    type: str
    pid: int
    id: int
    state: str
    lifespan: str
    timeout: int
    container: str
    args: str


app_data = ("com.foo,bar", "S", "1657", "1", "READY",
            "PERMANENT", "0", "supervisor.scope", "<none>")

# Here we can use the @auto_convert_args to wrap the constructor for AppInfo
app_info: AppInfo = auto_convert_args(AppInfo)(*app_data)
# or
create_AppInfo = auto_convert_args(AppInfo)
app_info: AppInfo = create_AppInfo(*app_data)

print(app_info)
# AppInfo(application='com.foo,bar', type='S', pid=1657, id=1, state='READY', lifespan='PERMANENT', timeout=0, container='supervisor.scope', args='<none>')

print_dict_type_table(app_info._asdict())
#     var_name | val_type        | value
# ------------------------------------------------------------
#  application | <class 'str'>   | 'com.foo,bar'
#         type | <class 'str'>   | 'S'
#          pid | <class 'int'>   | 1657
#           id | <class 'int'>   | 1
#        state | <class 'str'>   | 'READY'
#     lifespan | <class 'str'>   | 'PERMANENT'
#      timeout | <class 'int'>   | 0
#    container | <class 'str'>   | 'supervisor.scope'
#         args | <class 'str'>   | '<none>'
