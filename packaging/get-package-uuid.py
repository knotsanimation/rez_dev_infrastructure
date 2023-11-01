"""
Used to retrieve the uuid attribute of package.py the first timne you create one.
"""
import uuid

uuid_value = uuid.uuid4().hex
print(uuid_value)
