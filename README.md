# YettelHomeWork

SwiftUI iOS app for the highway vignette homework.

## Local Env + Signing Config

The project uses xcconfig files instead of a separate `.env` file.

- Shared: `Config/Env.xcconfig`
- Example: `Config/Env.local.xcconfig.example`
- Local (gitignored): `Config/Env.local.xcconfig`

Create your local config:

```bash
cp Config/Env.local.xcconfig.example Config/Env.local.xcconfig
```

Then set at least your Apple team ID:

```xcconfig
DEVELOPMENT_TEAM = <YOUR_APPLE_TEAM_ID>
```

`DEVELOPMENT_TEAM` is intentionally empty in shared settings, so without a local value, iOS signing/building will fail.

Runtime defaults can also be set in `Config/Env.local.xcconfig`:

```xcconfig
API_BASE_URL = http://localhost:8080
UITEST_MOCK_API = 1
UITEST_ORDER_RESULT = success
```

The shared scheme bridges these build settings to runtime environment variables automatically.

## API Configuration

The app now defaults to:

- `http://localhost:8080`

You can override backend URL via runtime config:

- Environment variable: `API_BASE_URL` (already bridged from `Env*.xcconfig` in the shared scheme)
- Launch argument: `-api-base-url <url>`

Launch argument takes precedence over environment value.

Examples:

- `API_BASE_URL=http://192.168.1.42:8080`
- `-api-base-url http://my-hostname.local:8080`

## UI Test Mock Mode

UI tests can run with fully mocked API responses.

When `UITEST_MOCK_API` is enabled, the app uses a dedicated UI-test mock client backed by PHP-parity fixtures (`api/index.php`) instead of the generic app preview mocks.

Supported flags:

- `UITEST_MOCK_API` (launch arg) or `UITEST_MOCK_API=1` (env, bridged from `Env*.xcconfig`)
- `-mock-order-result success|failure` (launch arg)
- `UITEST_ORDER_RESULT=success|failure` (env, bridged from `Env*.xcconfig`)

Current UI tests already launch with mock mode enabled in code.

## Xcode Scheme Setup

To set runtime values in Xcode:

1. Open `Product` -> `Scheme` -> `Edit Scheme...`
2. Select `Run` on the left.
3. Open the `Arguments` tab.

Set launch arguments (optional):

- `-api-base-url` then `http://<your-host-or-ip>:8080`
- `UITEST_MOCK_API`
- `-mock-order-result` then `success` or `failure`

Set environment variables (optional):

- `API_BASE_URL` = `http://<your-host-or-ip>:8080`
- `UITEST_MOCK_API` = `1`
- `UITEST_ORDER_RESULT` = `success` or `failure`

Notes:

- Launch argument `-api-base-url` overrides `API_BASE_URL`.
- If mock mode is enabled, live backend URL is ignored for API calls.

## Onboarding Note

If API calls fail on a new machine/device setup, the first thing to verify is `API_BASE_URL` (or `-api-base-url`) points to the reachable backend host/IP from that runtime environment.
