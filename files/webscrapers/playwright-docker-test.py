import asyncio
import requests
import os
from bs4 import BeautifulSoup
from dotenv import load_dotenv

load_dotenv()

# URLs to test
URL = "https://rsm-shiny-02.ucsd.edu/selenium/"
URL_AUTH = "https://rsm-shiny-02.ucsd.edu/selenium_auth/"


class PlaywrightDockerClient:
    """Client to connect to Playwright Docker container - similar to Selenium Remote WebDriver"""

    def __init__(self, base_url="http://rsm-playwright:3000"):
        self.base_url = base_url
        self.session = requests.Session()

    def _check_playwright_endpoint(self):
        """Check if Playwright container is available"""
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=2)
            return response.status_code == 200
        except requests.RequestException:
            return False

    async def execute_script(self, script_code):
        """Execute JavaScript in Playwright container"""
        try:
            response = self.session.post(
                f"{self.base_url}/execute", json={"script": script_code}, timeout=30
            )
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"Playwright execution failed: {response.text}")
        except Exception as e:
            raise Exception(f"Failed to execute script: {e}")


async def test_beautifulsoup_equivalent():
    """BeautifulSoup test - same as other scripts"""
    print("=== BeautifulSoup results ===")
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
    print("Can BeautifulSoup find the dynamic text?", soup.find(id="dynamicText"))


async def test_playwright_docker():
    """Test basic Playwright Docker functionality"""
    print("=== Playwright Docker Results ===")

    client = PlaywrightDockerClient()

    # Check if container is available
    if not client._check_playwright_endpoint():
        print("❌ Playwright container not available. Please start with:")
        print("   docker-compose -f docker-compose-playwright.yml up -d")
        return

    # Script to test basic functionality
    script = f"""
    const {{ chromium }} = require('playwright');
    const browser = await chromium.launch({{ headless: true }});
    const page = await browser.newPage();
    
    await page.goto('{URL}');
    
    const title = await page.title();
    const buttonExists = await page.locator('#showText').count() > 0;
    
    // Click button and get dynamic text
    if (buttonExists) {{
        await page.click('#showText');
        await page.waitForTimeout(1000);
    }}
    
    const dynamicText = await page.textContent('#dynamicText');
    
    await browser.close();
    
    return {{
        title: title,
        buttonExists: buttonExists,
        dynamicText: dynamicText
    }};
    """

    try:
        result = await client.execute_script(script)
        if result["success"]:
            data = result["result"]
            print(f"Title found by Playwright: {data['title']}")
            print(f"Button found by Playwright: {data['buttonExists']}")
            print(f"Dynamic text after click: {data['dynamicText']}")
        else:
            print("❌ Script execution failed")
    except Exception as e:
        print(f"❌ Error: {e}")


async def test_authentication_docker():
    """Test authentication using Playwright Docker container"""
    print("=== Playwright Docker Authentication ===")

    # Get credentials
    username = os.getenv("SELENIUM_USERNAME")
    password = os.getenv("SELENIUM_PASSWORD")

    if not username or not password:
        print("Missing credentials in .env file - skipping authentication test")
        return

    client = PlaywrightDockerClient()

    if not client._check_playwright_endpoint():
        print("❌ Playwright container not available")
        return

    # Load external JS and inject credentials
    js_file_path = os.path.join(os.path.dirname(__file__), "auth_and_click.js")
    with open(js_file_path, "r") as f:
        auth_js = f.read()

    auth_js = auth_js.replace("USERNAME_PLACEHOLDER", f'"{username}"')
    auth_js = auth_js.replace("PASSWORD_PLACEHOLDER", f'"{password}"')

    # Wrap the auth script in Playwright execution
    script = f"""
    const {{ chromium }} = require('playwright');
    const browser = await chromium.launch({{ headless: true }});
    const page = await browser.newPage();
    
    await page.goto('{URL_AUTH}');
    await page.waitForLoadState('networkidle');
    
    // Execute the authentication script
    await page.evaluate(`{auth_js}`);
    
    // Wait for completion and get results
    await page.waitForTimeout(2000);
    
    const buttonExists = await page.locator('#showText').count() > 0;
    const dynamicText = await page.textContent('#dynamicText').catch(() => '');
    
    await browser.close();
    
    return {{
        buttonExists: buttonExists,
        dynamicText: dynamicText
    }};
    """

    try:
        result = await client.execute_script(script)
        if result["success"]:
            data = result["result"]
            print("✅ Success!")
            print(f"🔘 Button found: {data['buttonExists']}")
            print(f"📝 Dynamic text: '{data['dynamicText']}'")
        else:
            print("❌ Authentication failed")
    except Exception as e:
        print(f"❌ Error: {e}")


async def main():
    """Run all tests"""
    print("Running Playwright Docker tests...\n")

    await test_beautifulsoup_equivalent()
    print()

    await test_playwright_docker()
    print()

    await test_authentication_docker()


if __name__ == "__main__":
    asyncio.run(main())
