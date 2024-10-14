#!/usr/bin/env python

try:
    # python3
    from urllib.request import urlopen, urlretrieve
except ImportError:
    # python2
    from urllib2 import urlopen
    from urllib import urlretrieve
import json
from os import path

language_models = [
    ("python", "intellisense-members-lstm"),
    ("javascript", "intellisense-members"),
    ("cplusplus", "intellisense-members"),
    ("python", "intellisense-members"),
    ("csharp", "intellisense-members"),
    ("java", "intellisense-members"),
    ("xaml", "intellisense-members"),
    ("sql", "intellisense-members"),
]

models = []
for language, model_type in language_models:
    url = "https://prod.intellicode.vsengsaas.visualstudio.com/api/v1/model/common/{}/{}/output/latest".format(
        language, model_type
    )
    payload = json.load(urlopen(url))
    model_id = payload["model"]["id"]
    output_id = payload["output"]["id"]
    analyzerName = payload["model"]["analyzer"]
    language = payload["model"]["language"]
    file_name = "/tmp/symlinks/vscodeModels/{}_{}".format(model_id, output_id)
    download_url = payload["output"]["blob"]["azureBlobStorage"]["readSasToken"]
    model = {
        "analyzerName": analyzerName,
        "languageName": language,
        "identity": {
            "modelId": model_id,
            "outputId": output_id,
            "modifiedTimeUtc": "2019-12-13T22:18:51.237Z",
        },
        "filePath": file_name,
        "lastAccessTimeUtc": "2020-07-18T02:32:58.446Z",
    }
    print("Downloading {}/{} model...".format(language, model_type))
    if not path.exists(file_name):
        urlretrieve(download_url, file_name)
    models.append(model)

with open("/tmp/symlinks/vscodeModels/generated_models.json", "w") as f:
    json.dump(models, f)
