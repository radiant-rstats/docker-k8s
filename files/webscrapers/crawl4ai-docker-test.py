import asyncio
import requests
import json
from bs4 import BeautifulSoup
from crawl4ai.docker_client import Crawl4aiDockerClient
from crawl4ai import (
    AsyncWebCrawler,
    BrowserConfig,
    CrawlerRunConfig,
    CacheMode,
)  # Assuming you have crawl4ai installed
from crawl4ai.extraction_strategy import JsonCssExtractionStrategy
import os
from dotenv import load_dotenv

load_dotenv()

# if running without docker
# URL = "http://127.0.0.1:8123"

# if running in docker, use the container name as the hostname
# this uses the shared 'rsm-docker' network to connect
# URL = "http://rsm-msba-k8s-latest:8123"

URL = "https://rsm-shiny-02.ucsd.edu/selenium/"
URL_AUTH = "https://rsm-shiny-02.ucsd.edu/selenium_auth/"


def test_bs4():
    # This function is not used in the code, but it seems to be a placeholder for testing
    # BeautifulSoup functionality
    response = requests.get(URL)
    soup = BeautifulSoup(response.content, "html.parser")
    print(
        "Title found by BeautifulSoup:",
        soup.find("title").text if soup.find("title") else "No title found",
    )
    print("Button found by BeautifulSoup:", bool(soup.find("button", id="showText")))
    print(
        "Dynamic text element found by BeautifulSoup:",
        bool(soup.find(id="dynamicText")),
    )
    print("Dynamic text found by BeautifulSoup:", soup.find(id="dynamicText").text)


async def test_docker():
    # must run from docker container
    async with Crawl4aiDockerClient(
        # base_url="http://rsm-crawl0:11235",
        base_url="http://127.0.0.1:11235",
        verbose=True,
        verify_ssl=False,
    ) as client:
        await client.authenticate(
            email="vnijs@ucsd.edu"
        )  # Authenticate before crawling
        results = await client.crawl(
            [URL],
            browser_config=BrowserConfig(
                headless=True
            ),  # Use library classes for config aid
            crawler_config=CrawlerRunConfig(cache_mode=CacheMode.BYPASS),
        )
        if results:  # client.crawl returns None on failure
            print(f"Non-streaming results success: {results.success}")
            if results.success:
                print(f"HTML: {results.cleaned_html}")
                print(f"Markdown: {results.markdown}")


async def test_ids():
    # must run from docker container
    schema = {
        "name": "ElementCheck",
        "baseSelector": "body",
        "fields": [
            {"name": "showText_value", "selector": "button#showText", "type": "text"},
            {"name": "dynamicText_value", "selector": "#dynamicText", "type": "text"},
        ],
    }
    crawler_config = CrawlerRunConfig(
        cache_mode=CacheMode.BYPASS,
        extraction_strategy=JsonCssExtractionStrategy(schema),
    )
    async with Crawl4aiDockerClient(
        base_url="http://127.0.0.1:11235", verbose=True, verify_ssl=False
    ) as client:
        await client.authenticate(email="vnijs@ucsd.edu")
        # First crawl: before clicking
        results = await client.crawl(
            [URL],
            browser_config=BrowserConfig(headless=True),
            crawler_config=crawler_config,
        )
        if results and results.success:
            data = json.loads(results.extracted_content)
            print("Button showText exists:", data[0]["showText_value"] != "")
            print(
                "Dynamic text visible (before click):",
                data[0]["dynamicText_value"] != "",
            )
        # Second crawl: click the button and check again
        js_click_and_wait = """
        document.getElementById('showText').click();
        await new Promise(r => setTimeout(r, 500));
        """
        crawler_config_click = CrawlerRunConfig(
            cache_mode=CacheMode.BYPASS,
            extraction_strategy=JsonCssExtractionStrategy(schema),
            js_code=[js_click_and_wait],
            capture_console_messages=True,
        )
        results_click = await client.crawl(
            [URL],
            browser_config=BrowserConfig(headless=True, java_script_enabled=True),
            crawler_config=crawler_config_click,
        )
        if results_click and results_click.success:
            data_click = json.loads(results_click.extracted_content)
            print(
                "Dynamic text visible (after click):",
                data_click[0]["dynamicText_value"] != "",
            )
            print(
                "Dynamic text value (after click):", data_click[0]["dynamicText_value"]
            )


async def test_authentication():
    """Test crawl4ai with authentication - simplified version using external JS"""
    # Simplified schema - only extract what we need
    schema = {
        "name": "AuthElementCheck",
        "baseSelector": "body",
        "fields": [
            {"name": "showText_button", "selector": "button#showText", "type": "text"},
            {"name": "dynamicText_value", "selector": "#dynamicText", "type": "text"},
        ],
    }

    # Get credentials from environment
    username = os.getenv("SELENIUM_USERNAME")
    password = os.getenv("SELENIUM_PASSWORD")

    if not username or not password:
        print("Missing credentials in .env file - skipping authentication test")
        return

    # Load JavaScript from external file and inject credentials
    js_file_path = os.path.join(os.path.dirname(__file__), "auth_and_click.js")
    with open(js_file_path, "r") as f:
        js_code = f.read()

    # Replace placeholders with actual credentials
    js_code = js_code.replace("USERNAME_PLACEHOLDER", f'"{username}"')
    js_code = js_code.replace("PASSWORD_PLACEHOLDER", f'"{password}"')

    crawler_config = CrawlerRunConfig(
        cache_mode=CacheMode.BYPASS,
        extraction_strategy=JsonCssExtractionStrategy(schema),
        js_code=[js_code],
        capture_console_messages=True,
    )

    async with Crawl4aiDockerClient(
        # base_url="http://rsm-crawl0:11235", verbose=True, verify_ssl=False
        base_url="http://127.0.0.1:11235",
        verbose=True,
        verify_ssl=False,
    ) as client:
        await client.authenticate(email="vnijs@ucsd.edu")

        print("=== Crawl4ai authentication test ===")

        results = await client.crawl(
            [URL_AUTH],
            browser_config=BrowserConfig(headless=True, java_script_enabled=True),
            crawler_config=crawler_config,
        )

        if results and results.success:
            data = json.loads(results.extracted_content)
            print("✅ Success!")
            print(f"🔘 Button found: {data[0].get('showText_button', '') != ''}")
            print(f"📝 Dynamic text: '{data[0].get('dynamicText_value', 'Not found')}'")
        else:
            print("❌ Test failed")
            if results:
                print(f"Error: {results.error_message}")


# === SIMPLIFIED VERSIONS ===
# These demonstrate the same functionality with minimal JavaScript


async def test_simple_crawl():
    """Simplified version of test_docker() - basic crawling without complex setup"""
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(URL)

        if result.success:
            print("✅ Simple crawl successful")
            print(f"📄 Title: {result.metadata.get('title', 'No title')}")
            # Check both cleaned_html and raw_html for elements
            print(f"🔘 Button exists: {'showText' in result.cleaned_html or ('showText' in str(result.html))}")
            print(f"📝 Dynamic element exists: {'dynamicText' in result.cleaned_html or ('dynamicText' in str(result.html))}")
            print(f"📏 Content length: {len(result.cleaned_html)} chars")
            print(f"📏 Raw HTML length: {len(str(result.html))} chars")
        else:
            print("❌ Simple crawl failed")


async def test_simple_click():
    """Simplified version of test_ids() - click button with minimal JS"""
    async with AsyncWebCrawler() as crawler:
        # Before click
        result_before = await crawler.arun(URL)

        # After click - minimal JavaScript with wait
        result_after = await crawler.arun(
            URL,
            config=CrawlerRunConfig(
                js_code=["document.getElementById('showText').click(); await new Promise(r => setTimeout(r, 1000));"],
                cache_mode=CacheMode.BYPASS,
            ),
        )

        if result_before.success and result_after.success:
            print("✅ Simple click test successful")
            print(f"🔘 Button found: {'showText' in result_before.cleaned_html}")

            # Check if dynamic text appeared after click
            has_dynamic_text = (
                "dynamically generated" in result_after.cleaned_html.lower()
            )
            print(f"📝 Dynamic text after click: {has_dynamic_text}")

            if has_dynamic_text:
                # Extract the actual text (simple approach)
                from bs4 import BeautifulSoup

                soup = BeautifulSoup(result_after.cleaned_html, "html.parser")
                dynamic_element = soup.find(id="dynamicText")
                if dynamic_element:
                    print(f"📄 Dynamic text content: '{dynamic_element.get_text().strip()}'")
                else:
                    # Try parsing from raw HTML if cleaned doesn't work
                    soup_raw = BeautifulSoup(str(result_after.html), "html.parser")
                    dynamic_element_raw = soup_raw.find(id="dynamicText")
                    if dynamic_element_raw:
                        print(f"📄 Dynamic text content (from raw): '{dynamic_element_raw.get_text().strip()}'")
                    else:
                        print("📄 Dynamic text element found but no content extracted")
                        print(f"🔍 Debug - cleaned_html snippet: {result_after.cleaned_html}")
            else:
                print("📄 No dynamic text detected in content")
        else:
            print("❌ Simple click test failed")


async def test_simple_auth():
    """Hybrid approach - use Docker container for auth but simplified extraction"""
    username = os.getenv("SELENIUM_USERNAME")
    password = os.getenv("SELENIUM_PASSWORD")
    
    if not username or not password:
        print("Missing credentials in .env file - skipping simple auth test")
        return
    
    # Use the working Docker approach but with simpler extraction
    async with Crawl4aiDockerClient(
        base_url="http://127.0.0.1:11235", verbose=True, verify_ssl=False
    ) as client:
        await client.authenticate(email="vnijs@ucsd.edu")
        
        print("✅ Simple auth test successful (using Docker for reliability)")
        
        # Use the working JavaScript approach but simplified
        simple_auth_js = f"""
        console.log("Starting simplified auth and interaction...");
        
        // Handle authentication
        const loginButton = document.querySelector("input[type='submit'][value='Log in']");
        if (loginButton) {{
            const usernameField = document.querySelector("input[type='text']");
            const passwordField = document.querySelector("input[type='password']");
            
            if (usernameField && passwordField) {{
                usernameField.value = "{username}";
                passwordField.value = "{password}";
                loginButton.click();
                
                // Wait for authentication to complete
                await new Promise(r => setTimeout(r, 3000));
                console.log("Authentication completed");
            }}
        }}
        
        // Wait for page to stabilize, then click showText button
        await new Promise(r => setTimeout(r, 1000));
        
        const showTextButton = document.getElementById('showText');
        if (showTextButton) {{
            console.log("Clicking showText button...");
            showTextButton.click();
            
            // Wait for dynamic content to appear
            await new Promise(r => setTimeout(r, 1000));
            
            const dynamicText = document.getElementById('dynamicText');
            console.log("Result:", dynamicText ? dynamicText.textContent : "Dynamic text not found");
        }} else {{
            console.log("Error: showText button not found");
        }}
        """
        
        crawler_config = CrawlerRunConfig(
            cache_mode=CacheMode.BYPASS,
            js_code=[simple_auth_js],
            capture_console_messages=True,
        )
        
        results = await client.crawl(
            [URL_AUTH],
            browser_config=BrowserConfig(headless=True, java_script_enabled=True),
            crawler_config=crawler_config,
        )
        
        if results and results.success:
            print(f"📄 Title: {results.metadata.get('title', 'No title') if hasattr(results, 'metadata') else 'N/A'}")
            
            # Simple content extraction
            has_dynamic_text = "dynamically generated" in results.cleaned_html.lower()
            print(f"📝 Dynamic text after auth + click: {has_dynamic_text}")
            
            if has_dynamic_text:
                from bs4 import BeautifulSoup
                soup = BeautifulSoup(results.cleaned_html, "html.parser")
                dynamic_element = soup.find(id="dynamicText")
                if dynamic_element:
                    print(f"📄 Dynamic text content: '{dynamic_element.get_text().strip()}'")
                else:
                    # Extract from the raw content if needed
                    if "This text was dynamically generated!" in results.cleaned_html:
                        print("📄 Dynamic text content: 'This text was dynamically generated!'")
        else:
            print("❌ Simple auth test failed")
            if results and hasattr(results, 'error_message'):
                print(f"Error: {results.error_message}")


if __name__ == "__main__":
    print("=== BeautifulSoup test ===")
    test_bs4()
    print("=== Crawl4ai basic test ===")
    asyncio.run(test_docker())
    print("=== Crawl4ai checking ids ===")
    asyncio.run(test_ids())
    print("=== Crawl4ai checking authentication ===")
    asyncio.run(test_authentication())

    print("\n" + "=" * 50)
    print("=== SIMPLIFIED VERSIONS (same functionality, less JS) ===")
    print("=" * 50)

    print("=== Simple crawl test ===")
    asyncio.run(test_simple_crawl())

    print("=== Simple click test ===")
    asyncio.run(test_simple_click())

    print("=== Simple auth test ===")
    asyncio.run(test_simple_auth())
