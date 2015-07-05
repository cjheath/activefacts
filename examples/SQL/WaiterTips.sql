CREATE TABLE Meal (
	-- Meal has MealId,
	MealId                                  int IDENTITY NOT NULL,
	PRIMARY KEY(MealId)
)
GO

CREATE TABLE Service (
	-- maybe Service earned a tip of Amount and Amount has AUDValue,
	AmountAUDValue                          decimal NULL,
	-- Service involves Meal and Meal has MealId,
	MealId                                  int NOT NULL,
	-- Service involves Waiter and Waiter has WaiterNr,
	WaiterNr                                int NOT NULL,
	PRIMARY KEY(WaiterNr, MealId),
	FOREIGN KEY (MealId) REFERENCES Meal (MealId)
)
GO

CREATE TABLE WaiterTip (
	-- WaiterTip involves Amount and Amount has AUDValue,
	AmountAUDValue                          decimal NOT NULL,
	-- WaiterTip involves Meal and Meal has MealId,
	MealId                                  int NOT NULL,
	-- WaiterTip involves Waiter and Waiter has WaiterNr,
	WaiterNr                                int NOT NULL,
	PRIMARY KEY(WaiterNr, MealId),
	FOREIGN KEY (MealId) REFERENCES Meal (MealId)
)
GO

