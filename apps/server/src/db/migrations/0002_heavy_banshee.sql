CREATE INDEX "idx_fielding_stats_innings" ON "fielding_stats" USING btree ("innings_id");--> statement-breakpoint
CREATE INDEX "idx_fielding_stats_player" ON "fielding_stats" USING btree ("player_id");--> statement-breakpoint
ALTER TABLE "player_career_stats" ADD CONSTRAINT "uq_career_stats_player_format" UNIQUE("player_id","format");