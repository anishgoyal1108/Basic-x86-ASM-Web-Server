import requests
import tempfile
import random
import string


def random_data():
    """Generate random data for testing."""
    return "".join(
        random.choices(string.ascii_letters + string.digits, k=random.randint(32, 256))
    ).encode()


def validate_get(data=None):
    if data is None:
        data = random_data()

    # Create a temporary file
    with tempfile.NamedTemporaryFile(delete=False) as temp_file:
        # Write the random data to the file
        temp_file.write(data)
        temp_file.flush()  # Ensure data is written

        # Get the name of the temporary file
        temp_file_path = temp_file.name

    # Attempt to send a GET request to the server
    try:
        response = requests.get(f"http://localhost{temp_file_path}", timeout=1)
        # Check if the response content matches the original data
        if response.content != data:
            return "GET: File contents not correct"
        else:
            return f"GET: Successful!\nFile Name: {temp_file.name}\nResponse: {response.content}"
    except requests.exceptions.ConnectionError:
        return "GET: Failed to connect"


if __name__ == "__main__":
    for _ in range(10):
        print(validate_get())
