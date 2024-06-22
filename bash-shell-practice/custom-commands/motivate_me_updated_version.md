## Install argcomplete

    pip install argcomplete



## Step 1: Create the Python Script

First, create a Python script named motivate_me.py with the following content:

    #!/usr/bin/env python3

    import argparse
    import requests
    import argcomplete

    categories = [
        "age", "alone", "amazing", "anger", "architecture", "art", "attitude", "beauty",
        "best", "birthday", "business", "car", "change", "communication", "computers", 
        "cool", "courage", "dad", "dating", "death", "design", "dreams", "education", 
        "environmental", "equality", "experience", "failure", "faith", "family", 
        "famous", "fear", "fitness", "food", "forgiveness", "freedom", "friendship", 
        "funny", "future", "god", "good", "government", "graduation", "great", "happiness", 
        "health", "history", "home", "hope", "humor", "imagination", "inspirational", 
        "intelligence", "jealousy", "knowledge", "leadership", "learning", "legal", 
        "life", "love", "marriage", "medical", "men", "mom", "money", "morning", "movies", 
        "success"
    ]

    def get_quote(category):
        api_url = f'https://api.api-ninjas.com/v1/quotes?category={category}'
        response = requests.get(api_url, headers={'X-Api-Key': 'ZvsuKhD'})
        if response.status_code == requests.codes.ok:
            quotes = response.json()
            if quotes:
                quote = quotes[0]
                print(f"quote: {quote['quote']}\nauthor: {quote['author']}\ncategory: {quote['category']}")
            else:
                print("No quotes found for this category.")
        else:
            print("Error:", response.status_code, response.text)

    def main():
        parser = argparse.ArgumentParser(description='Get a motivational quote.')
        parser.add_argument('category', nargs='?', default='happiness', choices=categories, help='Category of the quote (default: happiness)')
        argcomplete.autocomplete(parser)
        args = parser.parse_args()
        get_quote(args.category)

    if __name__ == "__main__":
        main()



## Enable Global Completion for Your Shell

For `argcomplete` to work, you need to enable global completion in your shell.

 ##### Activate global completion:

    activate-global-python-argcomplete --user

 ##### Add the following to your `~/.bashrc` or `~/.bash_profile`:

    eval "$(register-python-argcomplete motivate_me)"

 ##### Then, reload your shell configuration:

    source ~/.bashrc


### Instructions to Set Up and Run

    chmod +x motivate_me.py

### Place the Script in a Directory in Your PATH:

    mkdir -p ~/bin
    mv motivate_me.py ~/bin/motivate_me
    sudo mv motivate_me.py /usr/local/bin/motivate_me

### Ensure ~/bin is in Your PATH:

Add the following line to your ~/.bashrc or ~/.bash_profile if ~/bin is not already in your PATH:

    export PATH=$PATH:~/bin

Then, reload the configuration:

    source ~/.bashrc

## Run the Command

    motivate_me
