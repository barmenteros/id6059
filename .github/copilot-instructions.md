# GitHub Copilot Repository Custom Instructions
## THA KAD - ZARIUM CORE EA Project

### Project Overview
This is a sophisticated MQL4 Expert Advisor (EA) for MetaTrader 4 with advanced money management, signal processing, and risk management capabilities. The EA uses arrow-based signals with multiple filtering layers and dynamic position sizing.

### Core Architecture Principles

#### Modular Design Pattern
- **Separation of Concerns**: Each .mqh file handles a specific domain (OrderManagement, MoneyManagement, SignalProcessing, etc.)
- **Centralized Configuration**: GlobalSettings.mqh contains all input parameters and global variables
- **Event-Driven Architecture**: OnTick() drives the main trading logic with centralized state management

#### Key Architectural Components
```
Main EA File (THA KAD - ZARIUM CORE EA.mq4)
├── Core Trading Logic
│   ├── GlobalSettings.mqh (Input parameters, global variables, configuration structs)
│   ├── OrderManagement.mqh (Order execution, position management, multiplier system)
│   ├── MoneyManagement.mqh (Equity targets, lot sizing, account protection, pause logic)
│   ├── ArrowSignals.mqh (Signal detection, validation, order settings management)
│   ├── BreakevenFilter.mqh (Entry filtering, counter-based validation, signal evaluation)
│   ├── ReverseFilter.mqh (Counter-trend entries, reverse line management, price tracking)
│   ├── PositionSize.mqh (Dynamic lot calculation, account ratio system, balance adjustment)
│   └── TradingConditions.mqh (Market condition validation, time/spread/news filters)
│
├── Technical Analysis & Calculations
│   ├── StopLoss.mqh (Manual/ATR stop loss calculation, dynamic SL management)
│   ├── TakeProfit.mqh (MA cross detection, position closure on opposite signals)
│   ├── Trailing.mqh (Manual/ATR/Level-based trailing, breakeven logic, MHML integration)
│   ├── ProfitCalculations.mqh (Take profit determination, MHML marker calculations)
│   └── CommonFunctions.mqh (ATR calculations, MHML marker integration, utility functions)
│
├── Market Condition Filters
│   ├── SpreadManagement.mqh (Spread monitoring, trading permission based on spread)
│   ├── NewsFilter.mqh (Economic calendar integration, trading pause during news)
│   ├── TradingDays.mqh (Day-of-week trading permissions)
│   ├── TimeManagement.mqh (Hour-based trading windows, session management)
│   └── BreakevenPivotFilter.mqh (MHML-based entry filtering, percentage thresholds)
│
├── User Interface & Display
│   ├── InfoPanel.mqh (Chart panel creation, real-time status display, button handling)
│   ├── HorizontalLineOperations.mqh (Chart object management, hidden SL/TP lines)
│   ├── InputParametersHandler.mqh (Parameter validation, settings persistence)
│   └── CommonInputParams.mqh (Enums, structures, type definitions)
│
└── Utility & Infrastructure
    └── DebuggingTools.mqh (Development utilities, testing helpers)
```

### Critical Business Logic

#### Money Management System
- **Positive Equity Targets**: Automatic lot size and multiplier increases when profit targets reached
- **Negative Equity Limits**: Intelligent loss protection with position reduction
- **Account Ratio System**: Limits account balance usage via ratio (AC_Ratio_Limit:AC_Ratio_Actual)
- **Individual Profit Exit**: Closes individual trades at specified profit levels

#### Signal Processing Flow
1. **Arrow Signal Detection**: Primary entry signals from ArrowSignals_Jesse indicator
2. **Breakeven Filter**: Counters that require price to cross breakeven level N times
3. **Pivot Filter**: MHML-based position filtering using percentage thresholds
4. **Reverse Filter**: Counter-trend entries when price moves X pips away then returns
5. **Trading Conditions**: Time, spread, news, and day-of-week filtering

#### Position Management
- **Multiplier System**: Opens multiple orders per signal (CurrentBuyOrderMultiplier/CurrentSellOrderMultiplier)
- **Hidden Stop Loss/Take Profit**: Uses chart objects instead of broker SL/TP
- **Trailing Stop**: Manual, ATR-based, or level-based trailing
- **Swing Continuous Mode**: Opens additional orders on new bullish/bearish candles

### Coding Standards and Patterns

#### Error Handling
- Always use `PrintLog(__FUNCTION__, message, isImportant)` for logging
- Validate order selection with `if (!OrderSelect(ticket, SELECT_BY_TICKET)) return;`
- Check for trading context with `IsTradeContextFree()` before order operations
- Use retry mechanisms with exponential backoff for broker operations

#### Naming Conventions
- **Input Parameters**: Prefix with `IN_` (e.g., `IN_MagicNumber`, `IN_EnableStopLoss`)
- **Global Variables**: CamelCase (e.g., `CurrentBuyOrderMultiplier`, `TradingActive`)
- **Functions**: Descriptive CamelCase (e.g., `CalculateOrderLots`, `CheckEquityTargets`)
- **Constants**: ALL_CAPS with underscores (e.g., `BUY_SL_LINE_SUFFIX`, `MAGIC_ID`)

#### Data Structure Patterns
```cpp
// Always use structs for complex data
struct PositionInfo {
    double LotSize;
    string lotSizingDescription;
};

// Use enums for configuration options
enum LotSizingOptions {
    kManualLots,
    kPercentFreeMargin,
    kPercentEquity
};
```

#### Order Management Patterns
- **Always check order validity**: Use `IsValidOrder()` function
- **Normalize prices**: `NormalizeDouble(price, Digits())`
- **Use constants for order filtering**: `ONLY_MARKET`, `ONLY_PENDING`, `ALL_ORDERS`
- **Delete associated objects**: When closing orders, clean up SL/TP lines

### Common Issue Patterns and Solutions

#### Memory and Performance
- **Optimization Mode Handling**: Disable chart objects in `IsOptimization()`
- **Global Variable Cleanup**: Clear terminal globals on EA removal
- **Array Management**: Always use `ArrayResize()` before populating arrays

#### Trading Logic Issues
- **Signal Coordination**: Ensure arrow signals, BE filter, and pivot filter work together
- **Counter Reset Logic**: Reset breakeven/reverse counters on new bars or successful entries
- **Price Validation**: Always validate price levels against broker's STOPLEVEL

#### Money Management Edge Cases
- **Equity Calculation**: Use `AccountInfoDouble(ACCOUNT_EQUITY)` not balance
- **Lot Size Boundaries**: Respect broker's MINLOT, MAXLOT, and LOTSTEP
- **Ratio Validation**: Ensure AC_Ratio_Limit ≥ 2 and AC_Ratio_Actual ≤ 100

### Integration Points to Consider

#### Indicator Dependencies
- **ArrowSignals_Jesse**: Primary signal source (buffers 0=buy, 1=sell)
- **MH_ML_TS_Checkpoint**: Multi-timeframe levels for pivot filtering and TP calculation
- **ADX**: Optional trend strength confirmation
- **ATR**: Dynamic SL/TP calculation

#### Broker Compatibility
- **Hidden Features**: Chart objects don't work in Strategy Tester optimization
- **Slippage Handling**: Adjust for different broker execution models
- **Symbol Properties**: Always query SYMBOL_DIGITS, SYMBOL_POINT, etc.

### Testing and Debugging Guidelines

#### Strategy Tester Considerations
- Disable chart objects and global variables in optimization mode
- Use `IsTesting()` to modify behavior for backtesting
- Ensure all price calculations work with historical data

#### Common Debugging Approaches
1. **Signal Flow**: Trace from arrow detection → filters → order placement
2. **Counter States**: Log breakeven/reverse counter values and reset conditions
3. **Price Level Validation**: Check all SL/TP calculations against broker limits
4. **Memory Leaks**: Verify chart object cleanup on EA removal

### File Modification Guidelines

#### When Adding New Features
- Follow the modular pattern: create separate .mqh files for distinct functionality
- Add input parameters to GlobalSettings.mqh and InputParameters struct
- Update `AssignInputParametersToStruct()` function
- Add to info panel display if user-facing

#### When Fixing Bugs
- Always identify the root cause in the signal flow
- Test fixes in both live and optimization modes
- Verify money management calculations don't break risk limits
- Ensure chart object operations handle optimization mode

### Performance Optimization Notes
- Use static variables for persistent state in functions
- Minimize iCustom() calls by caching indicator values
- Avoid unnecessary string concatenations in OnTick()
- Use `OnNewBar()` detection to limit heavy calculations

This EA represents a production-grade trading system with complex interdependencies. Always consider the full signal flow and money management implications when making changes.
