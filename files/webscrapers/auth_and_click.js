// Authentication and button clicking script for crawl4ai
console.log("Starting authentication and interaction process...");

// Handle authentication if login form is present
const loginButton = document.querySelector("input[type='submit'][value='Log in']");
if (loginButton) {
    console.log("Login form detected - authenticating...");
    
    const usernameField = document.querySelector("input[type='text']");
    const passwordField = document.querySelector("input[type='password']");
    
    if (usernameField && passwordField) {
        // Credentials will be injected by Python
        usernameField.value = USERNAME_PLACEHOLDER;
        passwordField.value = PASSWORD_PLACEHOLDER;
        loginButton.click();
        
        // Wait for authentication to complete
        await new Promise(r => setTimeout(r, 3000));
        console.log("Authentication completed");
    }
} else {
    console.log("No authentication required");
}

// Wait for page to stabilize, then interact with showText button
await new Promise(r => setTimeout(r, 1000));

const showTextButton = document.getElementById('showText');
if (showTextButton) {
    console.log("Clicking showText button...");
    showTextButton.click();
    
    // Wait for dynamic content to appear
    await new Promise(r => setTimeout(r, 1000));
    
    const dynamicText = document.getElementById('dynamicText');
    console.log("Result:", dynamicText ? dynamicText.textContent : "Dynamic text not found");
} else {
    console.log("Error: showText button not found");
}
