-- Add UNIQUE constraints for ON CONFLICT DO UPDATE upsert support
-- Pre-check for duplicates before applying:
--   SELECT innings_id, player_id, COUNT(*) FROM batting_stats GROUP BY 1,2 HAVING COUNT(*) > 1;
--   SELECT innings_id, player_id, COUNT(*) FROM bowling_stats GROUP BY 1,2 HAVING COUNT(*) > 1;
--   SELECT innings_id, player_id, COUNT(*) FROM fielding_stats GROUP BY 1,2 HAVING COUNT(*) > 1;

ALTER TABLE "batting_stats" ADD CONSTRAINT "uq_batting_stats_innings_player" UNIQUE("innings_id", "player_id");
ALTER TABLE "bowling_stats" ADD CONSTRAINT "uq_bowling_stats_innings_player" UNIQUE("innings_id", "player_id");
ALTER TABLE "fielding_stats" ADD CONSTRAINT "uq_fielding_stats_innings_player" UNIQUE("innings_id", "player_id");
