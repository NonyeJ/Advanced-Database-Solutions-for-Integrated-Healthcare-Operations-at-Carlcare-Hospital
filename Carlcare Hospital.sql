CREATE DATABASE FoodserviceDB

USE FoodserviceDB;
GO

-- Add PK to Restaurant
ALTER TABLE restaurants -- Assuming the correct table name is 'Restaurant' with a capital 'R'
ADD CONSTRAINT PK_restaurants PRIMARY KEY (Restaurant_ID);

-- Add PK to Consumers
ALTER TABLE consumers  
ADD CONSTRAINT PK_consumers PRIMARY KEY (Consumer_ID);

-- Add composite PK to Ratings
ALTER TABLE ratings
ADD CONSTRAINT PK_ratings PRIMARY KEY (Consumer_ID, Restaurant_ID);

-- Add FK constraints to Ratings

ALTER TABLE ratings
ADD CONSTRAINT FK_ratings_consumer
FOREIGN KEY (Consumer_ID) REFERENCES consumers(Consumer_ID);

ALTER TABLE ratings
ADD CONSTRAINT FK_ratings_restaurant
FOREIGN KEY (Restaurant_ID) REFERENCES restaurants(Restaurant_ID);

-- Add composite PK to Restaurant_Cuisines
ALTER TABLE restaurant_Cuisines
ADD CONSTRAINT PK_restaurant_ruisines PRIMARY KEY (Restaurant_ID, Cuisine);

ALTER TABLE restaurant_cuisines
ADD CONSTRAINT FK_restaurantcuisines_restaurant
FOREIGN KEY (Restaurant_ID) REFERENCES restaurants(Restaurant_ID);

--Query to Show All Primary Keys
SELECT 
    t.name AS TableName,
    ind.name AS PrimaryKeyName,
    col.name AS ColumnName
FROM 
    sys.indexes ind 
INNER JOIN 
    sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id
INNER JOIN 
    sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id
INNER JOIN 
    sys.tables t ON ind.object_id = t.object_id
WHERE 
    ind.is_primary_key = 1
AND 
    t.is_ms_shipped = 0
ORDER BY 
    t.name, col.column_id;

--Query to Show All Foreign Keys
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN 
    sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN 
    sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN 
    sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN 
    sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
ORDER BY 
    tp.name, fk.name;


--Question 1: Write a query that lists all restaurants with a Medium range price with open area, serving Mexican food.

SELECT 
    R.Restaurant_ID, 
    R.Name, 
    R.City, 
    R.State, 
    R.Country, 
    R.Price, 
    R.Area
FROM 
    restaurants AS R  
INNER JOIN 
    Restaurant_Cuisines AS RC ON R.Restaurant_ID = RC.Restaurant_ID
WHERE 
    R.Price = 'Medium' AND 
    R.Area = 'Open' AND 
    RC.Cuisine = 'Mexican';


--Question 2: 
--Write a query that returns the total number of restaurants who have the overall rating  as 1 and are serving Mexican food. Compare the results with the total number of 
  --restaurants who have the overall rating as 1 serving Italian food.

SELECT 
    SUM(CASE WHEN RC.Cuisine = 'Mexican' THEN 1 ELSE 0 END) AS Mexican_Rating_1,
    SUM(CASE WHEN RC.Cuisine = 'Italian' THEN 1 ELSE 0 END) AS Italian_Rating_1
FROM 
    restaurants AS R
INNER JOIN 
    Restaurant_Cuisines AS RC ON R.Restaurant_ID = RC.Restaurant_ID
INNER JOIN 
    Ratings AS Ra ON R.Restaurant_ID = Ra.Restaurant_ID
WHERE 
    RC.Cuisine IN ('Mexican', 'Italian') AND 
    Ra.Overall_Rating = 1;


--Question 3: Calculate the average age of consumers who have given a 0 rating to the 'Service_rating' 
			--column.  

SELECT 
    ROUND(AVG(C.Age), 0) AS AverageAge
FROM 
    Consumers AS C
INNER JOIN 
    Ratings AS R ON C.Consumer_ID = R.Consumer_ID
WHERE 
    R.Service_Rating = 0;


--Question 4: . Write a query that returns the restaurants ranked by the youngest consumer. You should include the restaurant name and food rating that is given by that customer to 
				--the restaurant in your result. Sort the results based on food rating from high to low.
SELECT
    R.Restaurant_ID,
    Rest.Name AS RestaurantName,
    R.Food_Rating,
    MIN(C.Age) AS YoungestConsumerAge
FROM
    Ratings R
INNER JOIN Consumers C ON R.Consumer_ID = C.Consumer_ID
INNER JOIN restaurants Rest ON R.Restaurant_ID = Rest.Restaurant_ID
GROUP BY
    R.Restaurant_ID, Rest.Name, R.Food_Rating
ORDER BY
    R.Food_Rating DESC, YoungestConsumerAge ASC;

--Question 5:  Write a stored procedure for the query given as:
			   --Update the Service_rating of all restaurants to '2' if they have parking available, either as 'yes' or 'public'
CREATE PROCEDURE UpdateServiceRatingBasedOnParking
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Assuming 'Restaurant_ID' links 'Ratings' and 'restaurants' tables
    UPDATE Ratings
    SET Service_Rating = 2
    WHERE Restaurant_ID IN (
        SELECT Restaurant_ID
        FROM restaurants
        WHERE Parking IN ('yes', 'public')
    );
END;
GO

EXEC UpdateServiceRatingBasedOnParking;

--Validate the stored proedure
	--count how many ratings have been updated to '2' for the targeted restaurants:
SELECT COUNT(*) AS AfterUpdate
FROM Ratings R
JOIN restaurants Res ON R.Restaurant_ID = Res.Restaurant_ID
WHERE Res.Parking IN ('yes', 'public') AND R.Service_Rating = 2;

		--display a table showing restaurants where parking is 'public', along with their associated ratings
SELECT 
    Res.Restaurant_ID, 
    Res.Name AS RestaurantName, 
    Res.Parking, 
    R.Consumer_ID, 
    R.Food_Rating, 
    R.Service_Rating
FROM 
    restaurants Res
JOIN 
    Ratings R ON Res.Restaurant_ID = R.Restaurant_ID
WHERE 
    Res.Parking = 'public'
ORDER BY 
    Res.Restaurant_ID, R.Service_Rating DESC;

	--ADDITIONAL(PERSONAL QUERIES)	 


--QUERY 1: Restaurants with More Than Average Ratings (Using GROUP BY, HAVING)
SELECT R.Restaurant_ID, Rest.Name, AVG(R.Overall_Rating) AS AvgRating
FROM Ratings R
JOIN restaurants Rest ON R.Restaurant_ID = Rest.Restaurant_ID
GROUP BY R.Restaurant_ID, Rest.Name
HAVING AVG(R.Overall_Rating) > (
    SELECT AVG(Overall_Rating)
    FROM ratings
)
ORDER BY AvgRating DESC;

--Query 2: Cuisine Popularity Ranking (Using System Functions and GROUP BY)
SELECT RC.Cuisine, COUNT(*) AS NumberOfRestaurants, AVG(R.Overall_Rating) AS AvgRating
FROM Restaurant_Cuisines RC
JOIN Ratings R ON RC.Restaurant_ID = R.Restaurant_ID
GROUP BY RC.Cuisine
ORDER BY COUNT(*) DESC, AvgRating DESC;

--Query 3: Find Consumers Who Rated the Same Restaurant More Than Once (Using Nested queries-IN)

SELECT 
    C.Consumer_ID, 
    C.Age, 
    COUNT(*) AS NumberOfRatings
FROM 
    Ratings R
INNER JOIN 
    Consumers C ON R.Consumer_ID = C.Consumer_ID
WHERE 
    R.Consumer_ID IN (
        SELECT 
            Consumer_ID
        FROM 
            Ratings
        GROUP BY 
            Consumer_ID, Restaurant_ID
        HAVING 
            COUNT(*) > 1
    )
GROUP BY 
    C.Consumer_ID, C.Age
ORDER BY 
    NumberOfRatings DESC;


--Query 4:  Find the oldest consumers who have rated each restaurant (Using EXISTS, System Functions)
SELECT 
    Rest.Restaurant_ID, 
    Rest.Name AS RestaurantName, 
    C.Consumer_ID, 
    MAX(C.Age) AS OldestAge
FROM 
    restaurants Rest
INNER JOIN 
    Ratings R ON Rest.Restaurant_ID = R.Restaurant_ID
INNER JOIN 
    Consumers C ON R.Consumer_ID = C.Consumer_ID
WHERE 
    EXISTS (
        SELECT 1
        FROM Ratings R2
        WHERE R2.Restaurant_ID = Rest.Restaurant_ID AND R2.Consumer_ID = C.Consumer_ID
    )
GROUP BY 
    Rest.Restaurant_ID, Rest.Name, C.Consumer_ID
ORDER BY 
    OldestAge DESC; --ASC;

 --Top 5 customer who have visited the most restauarants along with all their details
SELECT TOP 5
    C.Consumer_ID,
    C.City,
    C.State,
    C.Country,
    C.Latitude,
    C.Longitude,
    C.Smoker,
    C.Drink_Level,
    C.Transportation_Method,
    C.Marital_Status,
    C.Children,
    C.Age,
    C.Occupation,
    C.Budget,
    COUNT(DISTINCT R.Restaurant_ID) AS NumberOfRestaurantsVisited
FROM 
    Ratings R
JOIN 
    Consumers C ON R.Consumer_ID = C.Consumer_ID
GROUP BY 
    C.Consumer_ID,
    C.City,
    C.State,
    C.Country,
    C.Latitude,
    C.Longitude,
    C.Smoker,
    C.Drink_Level,
    C.Transportation_Method,
    C.Marital_Status,
    C.Children,
    C.Age,
    C.Occupation,
    C.Budget
ORDER BY 
    NumberOfRestaurantsVisited DESC;




