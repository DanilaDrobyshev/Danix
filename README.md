<div align="center">

# Danix

**Algo trading platform for AI agents, on your own machine.**

[![release](https://img.shields.io/github/v/release/DanilaDrobyshev/Danix?label=release&color=2f81f7)](https://github.com/DanilaDrobyshev/Danix/releases/latest)
[![downloads](https://img.shields.io/github/downloads/DanilaDrobyshev/Danix/total?color=2ea043)](https://github.com/DanilaDrobyshev/Danix/releases)
![platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-555)
![exchanges](https://img.shields.io/badge/exchanges-Bybit%20%7C%20Binance%20%7C%20KuCoin-f0b90b)
[![MCP](https://img.shields.io/badge/MCP-server-8957e5)](#use-danix-with-any-ai-agent)
![price](https://img.shields.io/badge/price-free-2ea043)

A free, local algorithmic crypto trading platform. Build trading bots as visual node
graphs (no code), backtest them on real tick data, optimize them and run them live on
**Bybit**, **Binance** and **KuCoin**, futures and spot. A built-in **MCP server** lets
any AI agent (Claude, ChatGPT, Cursor, Gemini CLI, VS Code or a local LLM) design, edit,
backtest and explain strategies for you. The agent builds and tests. You review and launch.

[**Download**](https://github.com/DanilaDrobyshev/Danix/releases/latest) ·
[Use with an AI agent](#use-danix-with-any-ai-agent) ·
[Features](#features) ·
[Install](#install) ·
[FAQ](#faq) ·
[Report a bug](https://github.com/DanilaDrobyshev/Danix/issues)

</div>

---

## Why Danix

Most trading bot tools give an AI agent nothing to work with. Danix was designed so
that an agent and a person work on the same strategies, the same backtests and the
same bots:

- **The agent works, the person decides.** The agent creates and tests strategies.
  Anything that could open a trade waits for your approval, follows rules you set,
  or is refused.
- **What you see, the agent sees.** Strategies, charts, indicators, backtest
  windows and bot stats are shared between the UI and the agent. Edits show up live.
- **One graph from backtest to live.** The same node graph runs in the backtester
  and in the live bot, so what you tested is what trades.
- **Local and private.** No cloud account. Strategies, history and encrypted keys
  stay on your disk.

## Features

### Visual strategy builder (no code)
- Strategies are graphs of nodes and wires, in the style of Unreal Engine Blueprints.
- Indicators: SMA, EMA, RSI, MACD, Bollinger Bands, Stochastic, ATR, CCI,
  Williams %R, MFI, VWAP, Highest/Lowest and more. Candle patterns, math, arrays,
  loops and variables.
- Trading nodes for futures (long, short, stop loss, take profit, limit orders) and
  spot (market and limit orders, Post Only, amend, cancel, balances).
- Any variable can become a parameter for the optimizer.
- Validation, auto-layout, version history with diff and restore.
- A strategy is a plain JSON file you can copy, share and keep in git.

### Backtesting, MT5-style
- Tick mode on real Bybit, Binance and KuCoin trade archives, or candles only.
- Spread, latency (ping) and real maker/taker fees from your account, or set by hand.
- Multi-timeframe strategies, warmup, date range or last N candles.
- Visual mode replays the test on the chart with a speed control.
- Report with PnL, win rate, drawdown, fees, liquidations, balance and equity curves.
- History of recent runs that reopens instantly with the same settings.

### Optimizer
- Searches parameter values across all CPU cores.
- Walk-forward testing and a stability score that flags lucky results.

### Live trading bots
- Bybit, Binance and KuCoin, futures (USDT perpetual) and spot. Demo and Live accounts
  on Bybit and Binance, Live on KuCoin.
  Switching to Live always asks for confirmation.
- Start, pause, resume and stop bots. They resume after a restart.
- Risk controls: budget, max position and max daily loss per bot, global margin
  limit, and a stop-all kill switch.
- Bot review compares a bot's live trades with a backtest of the same period.
- Trading journal of every order, risk block and agent request.

### AI market research
- Ask the agent to explain a candle, a move or a period: trend phases, support and
  resistance, volume, higher-timeframe context and related headlines.
- Scan many tokens at once. Mark points and periods on the chart and get them explained.
- Saved reports and candle-close alerts.

### Three ways to control it
- **Web UI** at `http://127.0.0.1:7717`: charts, editor, backtests, bots.
- **CLI** for scripts: `Danix.exe backtest <strategy> --json`, `Danix.exe bot start <id>`,
  `Danix.exe approve <request>` and more. Every command has `--json` output.
- **MCP server** with 32 tools for AI agents.

## Use Danix with any AI agent

Danix speaks the [Model Context Protocol](https://modelcontextprotocol.io), so it
works with any MCP client.

**Claude Desktop:** install the `.mcpb` bundle from the
[latest release](https://github.com/DanilaDrobyshev/Danix/releases/latest), or add
this to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "danix": {
      "command": "C:\\Program Files\\Danix\\Danix.exe",
      "args": ["--mcp"]
    }
  }
}
```

**Claude Code:**

```bash
claude mcp add danix -- "C:\Program Files\Danix\Danix.exe" --mcp
```

**Cursor, VS Code, Gemini CLI, ChatGPT (developer mode), local LLMs:** add an MCP
server with the command `Danix.exe --mcp` (stdio) in your client's MCP settings.

### What you can ask

- "Build a BTCUSDT 15m strategy: long when RSI crosses 30 from below, take profit
  2%, stop loss 1%. Backtest it on the last 3 months with ticks."
- "Optimize the stop loss and take profit of my EMA Cross strategy and tell me if
  the result is stable or just lucky."
- "Why did SOL drop yesterday at 14:00? Mark the levels on my chart."
- "Compare my bot's live trades this week with a backtest of the same days."
- "Start this strategy as a bot on Binance Demo." (waits for your approval)

### What the agent can and cannot do

| The agent can | The agent cannot |
| --- | --- |
| Read the node catalog, create and edit strategies | See or use your API keys |
| Run backtests and optimization, open results in the UI | Withdraw or transfer funds (such keys are blocked) |
| Read charts, indicators, bots, positions and the journal | Switch an account to Live by itself |
| Request bot starts, stops and order changes | Trade outside the permissions you set |

## Supported exchanges

| Exchange | Futures | Spot | Demo | Live | Tick backtest |
| --- | --- | --- | --- | --- | --- |
| Bybit | Yes | Yes | Yes | Yes | Yes |
| Binance | Yes | Yes | Yes | Yes | Yes |
| KuCoin | Yes | Yes | No | Yes | Yes |

More exchanges are planned.

## Install

1. Download from [Releases](https://github.com/DanilaDrobyshev/Danix/releases/latest):
   - `Danix-<version>-win-x64-setup.exe`: Windows installer, updates itself (recommended);
   - `Danix-<version>-win-x64-portable.zip`: portable folder, no install, data next to the exe, update by hand;
   - `danix-<version>-linux-x64.tar.gz`: Linux build.
2. Windows may show a SmartScreen warning because the app is not code-signed yet.
   Click **More info → Run anyway**.
3. Open Danix, pick an exchange, add API keys (or use Demo), and open the bundled
   example strategies.

The Windows installer updates itself: Danix checks GitHub for a new signed release
and installs it in one click. The portable zip does not: download the new zip yourself.

**Install with an AI agent (Windows, no admin):** the agent can run one command. It
downloads the installer, checks its SHA-256, installs it silently for the current user
and connects Danix to Claude Code as an MCP server:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/DanilaDrobyshev/Danix/main/install.ps1 | iex"
```

## Privacy and security

- Everything runs locally. There is no Danix account and no cloud.
- API keys are encrypted on disk (AES-256-GCM + Windows DPAPI) and are never shown
  to the AI agent.
- Network traffic goes to the exchange APIs, the exchanges' public trade archives,
  public news and market data sources used by the research tools, and GitHub for
  updates. Your keys go only to the exchange.

## FAQ

### Can I let Claude or ChatGPT build a crypto trading bot?
Yes. Connect Danix as an MCP server and describe the strategy in plain words. The
agent builds it as a node graph you can open and edit, backtests it, and asks you
before it starts a bot.

### How do I backtest a trading strategy with an AI agent?
Ask the agent to run a backtest on a symbol, timeframe and period. Danix runs it on
tick data with fees, spread and latency, and opens the report and replay in the UI.

### Is Danix free?
Yes. Danix is free to use. A paid VPS option to keep bots running 24/7 without your
computer is planned.

### Which exchanges does Danix support?
Bybit, Binance and KuCoin, futures and spot. Bybit and Binance have Demo and Live
accounts, KuCoin has Live.

### Does the AI trade with my money?
Not on its own. Requests that could open a trade follow the permissions you set:
wait for your approval, run automatically within limits, or are refused.

### Do I need to code?
No. Strategies are visual node graphs. An AI agent can build them for you.

### How is Danix different from freqtrade, TradingView or 3Commas?
freqtrade is open source and Python-based: you write code. TradingView Pine Script
runs strategies on TradingView's charts and needs a third-party bridge to trade.
3Commas is a cloud service with ready-made bot types. Danix is a local desktop app
with a visual strategy language, a tick-level backtester, and an MCP server made
for AI agents. It supports fewer exchanges than these tools.

### Does it work on macOS?
Not yet. Danix runs on Windows; a Linux build is also available.

## Disclaimer

Trading cryptocurrencies involves substantial risk of loss. Backtest results do not
guarantee future returns. Danix is a tool, not financial advice.
