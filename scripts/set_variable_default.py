import re
import sys


def set_variable_default(variable: str, value: str, content: str) -> str:
    """
    This script uses regex to replace the text. It makes an assumption that the
    default value must be declared before an conditions are applied.
    """
    pat = '(variable\s+\"' + variable + '\"\s*{[^}]+\s+default\s*=\s\").*(\"\n)'

    rep = lambda m: f'{m.group(1)}{value}{m.group(2)}'
    return re.sub(
        pat,
        rep,
        content
    )


if __name__ == '__main__':
    var, val, *var_file = sys.argv[1:]
    file_path = ''.join(var_file) or 'variables.tf'

    print(f"Setting \"{var}\" to \"{val}\" in \"{file_path}\"")
    with open(file_path, 'r+', encoding="utf8") as f:
        txt = f.read()
        result = set_variable_default(var, val, txt)
        f.seek(0)
        f.write(result)
