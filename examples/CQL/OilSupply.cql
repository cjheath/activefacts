vocabulary OilSupply;

/*
 * Value Types
 */
Cost is written as Money;
Month Nr is written as Signed Integer(32);
Product Name is written as String;
Quantity is written as Unsigned Integer(32);
Refinery Name is written as String(80);
Region Name is written as String;
Season is written as String(6) restricted to {'Autumn', 'Spring', 'Summer', 'Winter'};
Transport Method is written as String restricted to {'Rail', 'Road', 'Sea'};
Year Nr is written as Signed Integer(32);

/*
 * Entity Types
 */
Month is identified by its Nr restricted to {1..12};
Month is in one Season;

Product is identified by its Name;

Refinery is identified by its Name;

Region is identified by its Name;

Transport Route is where
	Transport Method transportation is available from Refinery to Region,
	Transport Method transportation is available to Region from Refinery;
Transport Route incurs at most one Cost per kl;

Year is identified by its Nr;

Acceptable Substitutes is where
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

Supply Period is identified by Year and Month where
	Supply Period is in one Year,
	Supply Period is in one Month;

Production Forecast is where
	Refinery forecasts production of Product in Supply Period;
Production Forecast predicts at most one Cost;
Production Forecast is for one Quantity;

Regional Demand is where
	Region will need Product in Supply Period;
Regional Demand is for at most one Quantity;

