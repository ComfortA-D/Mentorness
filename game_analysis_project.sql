ALTER TABLE level_details2 DROP Row_Num;
ALTER TABLE player_details DROP Row_Num;
ALTER TABLE level_details2 RENAME COLUMN TimeStamp TO start_time;
-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0
SELECT
l.P_ID,
l.Dev_ID,
p.PName,
Difficulty
FROM level_details2 as l
LEFT JOIN player_details as p
USING(P_ID)
WHERE l.level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed
SELECT
p.L1_code,
avg(l.Kill_Count) AS avg_kill_count,
lives_Earned,
Score
FROM level_details2 AS l 
JOIN player_details AS p
USING(P_ID)
WHERE lives_Earned = 2  AND Stages_crossed >= 3
GROUP BY L1_Code;

-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.
SELECT
sum(Stages_crossed) as 'Total_Stages_crossed',
Difficulty,
level,
DEV_ID
FROM level_details2
WHERE level = 2 AND Dev_ID LIKE 'zm%'
GROUP BY Difficulty
ORDER BY Total_Stages_crossed DESC;

-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.
SELECT
DISTINCT P_ID,
count(DISTINCT (DATE(start_time))) AS 'no_unique_dates'
FROM level_details2
GROUP BY P_ID
HAVING no_unique_dates > 1;

-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.
SELECT 
*, 
SUM(Kill_Count) as total_kill_count, 
AVG(Kill_Count) AS 'avg_kill_count'
FROM level_details2
GROUP BY P_ID, level
HAVING Kill_Count > avg_kill_count AND Difficulty = 'Medium';

-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.
SELECT
l.level,
p.L1_code,
p.L2_code,
sum(l.Lives_Earned) as total_lives_earned
FROM level_details2 as l INNER JOIN player_details as p
USING (P_ID)
GROUP BY l.level
HAVING level != 0
ORDER BY level;

-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well. 
WITH top3 AS 
(SELECT Dev_ID, Score, Difficulty, ROW_NUMBER() 
OVER(PARTITION BY Dev_ID  ORDER BY Score DESC) AS rn FROM level_details2)
SELECT * FROM top3 WHERE rn <=3; 

-- Q8) Find first_login datetime for each device id
SELECT
distinct Dev_ID,
min((start_time)) as 'first_login_datetime'
FROM level_details2
GROUP BY Dev_ID;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.
WITH score_point AS (
	SELECT 
			Score,
			Difficulty,
            Dev_ID,
			RANK() OVER (PARTITION BY Difficulty  ORDER BY Score) AS score_rank 
	FROM 
			level_details2
)
SELECT 
			Score,
			Difficulty,
            Dev_ID,
            score_rank
FROM score_point
WHERE score_rank <= 5;

-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.
SELECT
P_ID,
Dev_ID,
min((start_time)) AS 'first_login_date'
FROM level_details2
GROUP BY P_ID;

-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played 
-- by the player until that date.
-- a) window function
SELECT 
P_ID,
Date(start_time) as Date,
sum(Kill_Count) OVER (PARTITION BY P_ID ORDER BY start_time) as total_number_of_games
FROM level_details2;

-- b) without window function
SELECT
P_ID,
Date(start_time) as Date,
sum(Kill_Count) as Total_Kill_Count
FROM level_details2
GROUP BY P_ID, Date;

-- Q12) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime
SELECT 
P_ID,
start_time as Datetime,
sum(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY start_time) as  cumulative_sum_of_stages_crossed
FROM level_details2;

-- Q13) Extract top 3 highest sum of score for each device id and the corresponding player_id 
SELECT 
DISTINCT Dev_ID,
P_ID,
sum(Score) as highest_score
FROM level_details2
GROUP BY Dev_ID
ORDER BY highest_score DESC
LIMIT 3;

-- Q14) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id
SELECT 
P_ID,
sum(Score) as total_score
FROM level_details2
GROUP BY P_ID
HAVING total_score > 
					(
                    SELECT AVG(Score)*0.5 
                    FROM level_details2
                    );
                    
-- Q15) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.
DELIMITER $$
CREATE PROCEDURE top_n_headshots_count(IN parameter_rn INT)
BEGIN
	WITH top_N AS 
	(SELECT Dev_ID, Score, Difficulty, ROW_NUMBER() 
	OVER(PARTITION BY Dev_ID  ORDER BY Score DESC) AS rn FROM level_details2)
	SELECT * FROM top_N WHERE rn <= parameter_rn; 
END $$
DELIMITER ;
-- CALLING THE PROCEDURE TO FIND TOP N HEAD_SHOTS
CALL top_n_headshots_count(5);
-- Q16) Create a function to return sum of Score for a given player_id.
SELECT 
DISTINCT P_ID,
sum(Score) AS Total_Score
FROM player_details AS p LEFT JOIN level_details2 AS l
USING(P_ID)
GROUP BY P_ID
ORDER BY Total_Score DESC