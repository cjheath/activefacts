CREATE TABLE Meal (
	-- Meal has MealId,
	MealId                                  int IDENTITY NOT NULL,
	PRIMARY KEY(MealId)
)
GO

CREATE TABLE Service (
	-- maybe Service earned a tip of Amount and Amount has AUDValue,
	AmountAUDValue                          decimal NULL,
	-- Service is where Waiter served Meal and Meal has MealId,
	MealId                                  int NOT NULL,
	-- Service is where Waiter served Meal and Waiter has WaiterNr,
	WaiterNr                                int NOT NULL,
	PRIMARY KEY(WaiterNr, MealId),
	FOREIGN KEY (MealId) REFERENCES Meal (MealId)
)
GO

CREATE TABLE WaiterTip (
	-- WaiterTip is where Waiter for serving Meal reported a tip of Amount and Amount has AUDValue,
	AmountAUDValue                          decimal NOT NULL,
	-- WaiterTip is where Waiter for serving Meal reported a tip of Amount and Meal has MealId,
	MealId                                  int NOT NULL,
	-- WaiterTip is where Waiter for serving Meal reported a tip of Amount and Waiter has WaiterNr,
	WaiterNr                                int NOT NULL,
	PRIMARY KEY(WaiterNr, MealId),
	FOREIGN KEY (MealId) REFERENCES Meal (MealId)
)
GO

