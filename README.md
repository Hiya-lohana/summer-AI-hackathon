# Safenet AI - Citizen Cybersecurity Shield
*A Flutter-based safety assistant for senior citizens to identify digital fraud, payment scams, and trigger distress alerts.*

---

## 🚀 How to Open & Run the Project in VS Code

If you or your team members have pulled this repository and are seeing errors in VS Code, follow these setup steps to initialize the project correctly:

### 📋 Prerequisites
1.  **Flutter SDK**: Ensure you have Flutter installed (compatible with SDK version `^3.11.0` or higher). Check using:
    ```bash
    flutter --version
    ```
2.  **VS Code Extensions**: Install the official **Dart** and **Flutter** extensions from the VS Code Marketplace.

---

### 🛠️ Setup Steps

#### 1. Open the Project
Open VS Code, select **File > Open Folder**, and choose the `summer-AI-hackathon-main` directory.

#### 2. Get Dependencies (Fix Import Errors)
When you first clone or pull the project, VS Code will display red error lines on import statements. This is because the packages are not yet downloaded.
*   Open a new terminal in VS Code (**Terminal > New Terminal**).
*   Run the following command to download all libraries:
    ```bash
    flutter pub get
    ```
*   *Note: This generates the package configuration maps and instantly resolves the import errors.*

#### 3. Setup Environment Variables
The application uses the Gemini AI service which requires a `.env` file containing an API key.
*   In the root directory of the project, locate the template file named `.env.example`.
*   Create a copy of it and name it `.env`:
    *   **Windows (Command Prompt)**: `copy .env.example .env`
    *   **macOS / Linux / PowerShell**: `cp .env.example .env`
*   Open the new `.env` file and replace `your_gemini_api_key_here` with your actual **Gemini API Key**.
*   *Note: The app is equipped with try-catch fallbacks; if you run without a `.env` file, the app will run with local fallback engines instead of crashing.*

#### 4. Run the Application
*   Connect an Android/iOS device, start an emulator, or choose Chrome.
*   Select **Run > Start Debugging** (or press `F5` on your keyboard).
*   Alternatively, run via the terminal:
    ```bash
    flutter run
    ```

---

## 🔍 Troubleshooting VS Code Errors

*   **Red lines still visible after `flutter pub get`**:
    Open the VS Code Command Palette (`Ctrl + Shift + P` on Windows/Linux or `Cmd + Shift + P` on macOS), type **Developer: Reload Window**, and press Enter. This forces the Dart Analyzer to refresh its cache.
*   **Target of URI doesn't exist**:
    This means the local package cache hasn't synced. Run `flutter clean` followed by `flutter pub get` to regenerate dependencies.
*   **Android build fails**:
    Make sure you have Java 17 installed and your Android SDK paths are set correctly in your environment variables.
