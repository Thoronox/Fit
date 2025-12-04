# ExerciseExecutionView Performance Logging Guide

## Overview
This document describes the logging added to diagnose the 10-second unresponsiveness when clicking into edit fields in ExerciseExecutionView.

## Logging Symbols and What They Track

### 🔴 Red Circle - Main View Lifecycle
- **ExerciseExecutionView.body rendering START/END**: Tracks when the main view body is being evaluated
- **ExerciseExecutionView.onAppear START/END**: Tracks the onAppear lifecycle method
- **setupInitialState START/END**: Tracks the initialization of the view state
- **List rendering START**: Tracks when the List view is being rendered
- **ForEach rendering set X**: Tracks each set row being rendered in the ForEach loop

### 🔵 Blue Circle - Focus State Changes
- **focusedField changed from X to Y**: Tracks when the focus changes between fields
  - This is the KEY metric - watch for delays between when focus is requested and when it actually changes

### 🟣 Purple Circle - SetRowViewWrapper
- **SetRowViewWrapper rendering START/END**: Tracks the wrapper component that creates the @Bindable
- **@Bindable created**: Tracks when the bindable variable is created

### 🟢 Green Circle - SetRowView
- **SetRowView rendering START/END**: Tracks the main row view for each set

### 🟡 Yellow Circle - TextField Components
- **RepsTextField rendering START/END**: Tracks when the reps input field is rendered
- **RepsTextField FOCUSED/UNFOCUSED**: Tracks when the reps field gains/loses focus
- **WeightTextField rendering START/END**: Tracks when the weight input field is rendered
- **WeightTextField FOCUSED/UNFOCUSED**: Tracks when the weight field gains/loses focus
- **WeightTextField onChange START/END**: Tracks when the weight value changes

## How to Use This Logging

### Step 1: Reproduce the Issue
1. Run the app in Xcode
2. Navigate to an exercise execution view
3. Try to click into one of the edit fields
4. Watch the Xcode console

### Step 2: Analyze the Timestamps
Look for time gaps between log entries. The issue will likely show up as one of these patterns:

#### Pattern A: Slow Focus Change
```
🔵 [timestamp1] focusedField changed from nil to reps(0)
🔴 [timestamp1 + 10s] List rendering START
```
**Diagnosis**: Focus state change is triggering expensive re-renders

#### Pattern B: Slow List/ForEach Rendering
```
🔴 [timestamp1] List rendering START - 5 sets
🔴 [timestamp1 + 10s] ForEach rendering set 1
```
**Diagnosis**: List initialization or enumeration is expensive

#### Pattern C: Slow Row Rendering
```
🔴 [timestamp1] ForEach rendering set 1
🟣 [timestamp1 + 2s] SetRowViewWrapper rendering START: set 1
🟢 [timestamp1 + 4s] SetRowView rendering START: set 1
```
**Diagnosis**: Individual row views are expensive to create

#### Pattern D: Slow TextField Creation
```
🟢 [timestamp1] SetRowView rendering START: set 1
🟡 [timestamp1 + 5s] RepsTextField rendering START: set 1
🟡 [timestamp1 + 7s] WeightTextField rendering START: set 1
```
**Diagnosis**: TextField components are expensive to create

### Step 3: Common Culprits to Look For

1. **Multiple Body Re-renders**: If you see many "body rendering START" messages in quick succession
   - Suggests SwiftData observation is triggering cascading updates

2. **All Rows Re-rendering**: If all SetRowView messages appear when focusing one field
   - Suggests the List is re-creating all rows unnecessarily

3. **Long Gap Between Focus Request and Actual Focus**: 
   ```
   [time1] ExerciseExecutionView setting focusedField to reps(0)
   [time1 + 10s] focusedField changed from nil to reps(0)
   ```
   - Suggests the state update is blocked by expensive operations

## Next Steps After Diagnosis

Once you identify where the time is being spent:

1. **If it's in List/ForEach**: Consider virtualization or lazy loading strategies
2. **If it's in @Bindable creation**: May need to restructure data binding
3. **If it's in TextField rendering**: May need to simplify TextField configuration
4. **If it's cascading re-renders**: Need to break observation chains (use @Query with filters, or cache values)

## Removing the Logging

Once the issue is identified and fixed, search for these patterns to remove logging:
- `let _ = print("🔴`
- `let _ = print("🔵`
- `let _ = print("🟣`
- `let _ = print("🟢`
- `let _ = print("🟡`
- `print("🔴`
- `print("🔵`
- `print("🟣`
- `print("🟢`
- `print("🟡`
