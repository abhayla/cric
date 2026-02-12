CREATE TABLE "ball_types" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(50) NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "dismissal_types" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(50) NOT NULL,
	"code" varchar(10) NOT NULL,
	"requires_fielder" boolean DEFAULT false NOT NULL,
	"requires_bowler_credit" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fielding_positions" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(50) NOT NULL,
	"code" varchar(10) NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "wagon_wheel_zones" (
	"id" serial PRIMARY KEY NOT NULL,
	"zone_code" varchar(10) NOT NULL,
	"label" varchar(50) NOT NULL,
	"start_angle" integer NOT NULL,
	"end_angle" integer NOT NULL,
	"side" varchar(10) NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"firebase_uid" varchar(128) NOT NULL,
	"phone" varchar(15),
	"email" varchar(255),
	"display_name" varchar(60) NOT NULL,
	"avatar_url" text,
	"batting_style" varchar(20),
	"bowling_style" varchar(30),
	"player_role" varchar(20),
	"location" varchar(100),
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_firebase_uid_unique" UNIQUE("firebase_uid")
);
--> statement-breakpoint
CREATE TABLE "team_rosters" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"team_id" uuid NOT NULL,
	"player_id" uuid NOT NULL,
	"jersey_number" integer,
	"role" varchar(20) NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"joined_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_team_rosters_team_player" UNIQUE("team_id","player_id")
);
--> statement-breakpoint
CREATE TABLE "teams" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(100) NOT NULL,
	"logo_url" text,
	"location" varchar(100),
	"created_by" uuid NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "match_analytics" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"match_id" uuid NOT NULL,
	"manhattan_data" jsonb,
	"worm_data" jsonb,
	"mvp_scores" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "match_players" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"match_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"player_id" uuid NOT NULL,
	"batting_order" integer,
	"is_playing" boolean DEFAULT true NOT NULL,
	"is_captain" boolean DEFAULT false NOT NULL,
	"is_keeper" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_match_players_match_team_player" UNIQUE("match_id","team_id","player_id")
);
--> statement-breakpoint
CREATE TABLE "match_result" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"match_id" uuid NOT NULL,
	"winner_team_id" uuid,
	"result_type" varchar(20) NOT NULL,
	"margin" integer,
	"man_of_match_id" uuid,
	"summary" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "match_result_match_id_unique" UNIQUE("match_id")
);
--> statement-breakpoint
CREATE TABLE "matches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"home_team_id" uuid NOT NULL,
	"away_team_id" uuid NOT NULL,
	"tournament_id" uuid,
	"format" varchar(20) NOT NULL,
	"total_overs" integer NOT NULL,
	"ball_type_id" integer NOT NULL,
	"venue" varchar(200),
	"toss_winner_id" uuid,
	"toss_decision" varchar(10),
	"status" varchar(20) DEFAULT 'setup' NOT NULL,
	"scorer_id" uuid,
	"players_per_side" integer DEFAULT 11 NOT NULL,
	"max_overs_per_bowler" integer,
	"wide_runs" integer DEFAULT 1 NOT NULL,
	"no_ball_runs" integer DEFAULT 1 NOT NULL,
	"powerplay_overs" integer,
	"created_by" uuid NOT NULL,
	"match_date" date NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "innings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"match_id" uuid NOT NULL,
	"innings_number" integer NOT NULL,
	"batting_team_id" uuid NOT NULL,
	"bowling_team_id" uuid NOT NULL,
	"total_runs" integer DEFAULT 0 NOT NULL,
	"total_wickets" integer DEFAULT 0 NOT NULL,
	"total_overs" numeric(5, 1) DEFAULT '0.0' NOT NULL,
	"total_extras" integer DEFAULT 0 NOT NULL,
	"total_wides" integer DEFAULT 0 NOT NULL,
	"total_no_balls" integer DEFAULT 0 NOT NULL,
	"total_byes" integer DEFAULT 0 NOT NULL,
	"total_leg_byes" integer DEFAULT 0 NOT NULL,
	"is_super_over" boolean DEFAULT false NOT NULL,
	"super_over_number" integer,
	"is_completed" boolean DEFAULT false NOT NULL,
	"completed_reason" varchar(30),
	"target" integer,
	"penalty_runs" integer DEFAULT 0 NOT NULL,
	"run_rate" numeric(5, 2),
	"dot_ball_percentage" numeric(5, 2),
	"boundary_percentage" numeric(5, 2),
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "overs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"innings_id" uuid NOT NULL,
	"over_number" integer NOT NULL,
	"bowler_id" uuid NOT NULL,
	"runs_conceded" integer DEFAULT 0 NOT NULL,
	"wickets_taken" integer DEFAULT 0 NOT NULL,
	"wides" integer DEFAULT 0 NOT NULL,
	"no_balls" integer DEFAULT 0 NOT NULL,
	"is_maiden" boolean DEFAULT false NOT NULL,
	"is_completed" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_overs_innings_over" UNIQUE("innings_id","over_number")
);
--> statement-breakpoint
CREATE TABLE "deliveries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"innings_id" uuid NOT NULL,
	"over_number" integer NOT NULL,
	"ball_number" integer NOT NULL,
	"sequence_number" integer NOT NULL,
	"striker_id" uuid NOT NULL,
	"non_striker_id" uuid NOT NULL,
	"bowler_id" uuid,
	"runs_from_bat" integer DEFAULT 0 NOT NULL,
	"is_wide" boolean DEFAULT false NOT NULL,
	"wide_runs" integer DEFAULT 0 NOT NULL,
	"is_no_ball" boolean DEFAULT false NOT NULL,
	"no_ball_runs" integer DEFAULT 0 NOT NULL,
	"is_bye" boolean DEFAULT false NOT NULL,
	"bye_runs" integer DEFAULT 0 NOT NULL,
	"is_leg_bye" boolean DEFAULT false NOT NULL,
	"leg_bye_runs" integer DEFAULT 0 NOT NULL,
	"total_runs" integer DEFAULT 0 NOT NULL,
	"is_wicket" boolean DEFAULT false NOT NULL,
	"is_legal" boolean DEFAULT true NOT NULL,
	"is_boundary_four" boolean DEFAULT false NOT NULL,
	"is_boundary_six" boolean DEFAULT false NOT NULL,
	"is_free_hit" boolean DEFAULT false NOT NULL,
	"is_penalty" boolean DEFAULT false NOT NULL,
	"wagon_wheel_zone_id" integer,
	"timestamp" timestamp DEFAULT now() NOT NULL,
	"synced" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fall_of_wickets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"innings_id" uuid NOT NULL,
	"wicket_number" integer NOT NULL,
	"runs_at_fall" integer NOT NULL,
	"overs_at_fall" numeric(5, 1) NOT NULL,
	"dismissed_player_id" uuid NOT NULL,
	"delivery_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "wickets_by_delivery" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"delivery_id" uuid NOT NULL,
	"dismissed_player_id" uuid NOT NULL,
	"dismissal_type_id" integer NOT NULL,
	"fielder_id" uuid,
	"bowler_credited" boolean NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "batting_stats" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"innings_id" uuid NOT NULL,
	"player_id" uuid NOT NULL,
	"batting_position" integer NOT NULL,
	"runs_scored" integer DEFAULT 0 NOT NULL,
	"balls_faced" integer DEFAULT 0 NOT NULL,
	"fours" integer DEFAULT 0 NOT NULL,
	"sixes" integer DEFAULT 0 NOT NULL,
	"strike_rate" numeric(6, 2),
	"is_not_out" boolean DEFAULT true NOT NULL,
	"dismissal_type_id" integer,
	"dismissed_by_id" uuid,
	"fielder_id" uuid,
	"is_retired_hurt" boolean DEFAULT false NOT NULL,
	"minutes_batted" integer,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bowling_stats" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"innings_id" uuid NOT NULL,
	"player_id" uuid NOT NULL,
	"overs_bowled" numeric(4, 1) DEFAULT '0.0' NOT NULL,
	"maidens" integer DEFAULT 0 NOT NULL,
	"runs_conceded" integer DEFAULT 0 NOT NULL,
	"wickets_taken" integer DEFAULT 0 NOT NULL,
	"economy_rate" numeric(5, 2),
	"wides" integer DEFAULT 0 NOT NULL,
	"no_balls" integer DEFAULT 0 NOT NULL,
	"dot_balls" integer DEFAULT 0 NOT NULL,
	"fours_conceded" integer DEFAULT 0 NOT NULL,
	"sixes_conceded" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fielding_stats" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"innings_id" uuid NOT NULL,
	"player_id" uuid NOT NULL,
	"catches" integer DEFAULT 0 NOT NULL,
	"run_outs" integer DEFAULT 0 NOT NULL,
	"stumpings" integer DEFAULT 0 NOT NULL,
	"direct_hits" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "player_career_stats" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"player_id" uuid NOT NULL,
	"format" varchar(20) NOT NULL,
	"matches_played" integer DEFAULT 0 NOT NULL,
	"innings_batted" integer DEFAULT 0 NOT NULL,
	"total_runs" integer DEFAULT 0 NOT NULL,
	"highest_score" integer DEFAULT 0 NOT NULL,
	"batting_average" numeric(6, 2),
	"batting_strike_rate" numeric(6, 2),
	"fifties" integer DEFAULT 0 NOT NULL,
	"hundreds" integer DEFAULT 0 NOT NULL,
	"fours" integer DEFAULT 0 NOT NULL,
	"sixes" integer DEFAULT 0 NOT NULL,
	"not_outs" integer DEFAULT 0 NOT NULL,
	"innings_bowled" integer DEFAULT 0 NOT NULL,
	"overs_bowled" numeric(6, 1),
	"runs_conceded" integer DEFAULT 0 NOT NULL,
	"wickets_taken" integer DEFAULT 0 NOT NULL,
	"bowling_average" numeric(6, 2),
	"bowling_economy" numeric(5, 2),
	"bowling_strike_rate" numeric(6, 2),
	"best_bowling_wickets" integer DEFAULT 0 NOT NULL,
	"best_bowling_runs" integer DEFAULT 0 NOT NULL,
	"three_wicket_hauls" integer DEFAULT 0 NOT NULL,
	"five_wicket_hauls" integer DEFAULT 0 NOT NULL,
	"catches" integer DEFAULT 0 NOT NULL,
	"run_outs" integer DEFAULT 0 NOT NULL,
	"stumpings" integer DEFAULT 0 NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "tournament_fixtures" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tournament_id" uuid NOT NULL,
	"match_id" uuid,
	"round_number" integer NOT NULL,
	"round_type" varchar(20) NOT NULL,
	"fixture_order" integer NOT NULL,
	"group_name" varchar(10),
	"home_team_id" uuid NOT NULL,
	"away_team_id" uuid NOT NULL,
	"scheduled_date" date,
	"scheduled_time" time,
	"estimated_duration_minutes" integer,
	"venue" varchar(200),
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "tournament_groups" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tournament_id" uuid NOT NULL,
	"name" varchar(10) NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_tournament_groups_tournament_name" UNIQUE("tournament_id","name")
);
--> statement-breakpoint
CREATE TABLE "tournament_requests" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tournament_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"requested_by" uuid NOT NULL,
	"status" varchar(20) DEFAULT 'pending' NOT NULL,
	"rejection_reason" varchar(500),
	"requested_at" timestamp DEFAULT now() NOT NULL,
	"resolved_at" timestamp,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_tournament_requests_tournament_team" UNIQUE("tournament_id","team_id")
);
--> statement-breakpoint
CREATE TABLE "tournament_standings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tournament_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"group_name" varchar(10),
	"played" integer DEFAULT 0 NOT NULL,
	"won" integer DEFAULT 0 NOT NULL,
	"lost" integer DEFAULT 0 NOT NULL,
	"tied" integer DEFAULT 0 NOT NULL,
	"no_result" integer DEFAULT 0 NOT NULL,
	"points" integer DEFAULT 0 NOT NULL,
	"nrr" numeric(6, 3) DEFAULT '0.000' NOT NULL,
	"total_runs_scored" integer DEFAULT 0 NOT NULL,
	"total_overs_faced" numeric(6, 1) DEFAULT '0.0' NOT NULL,
	"total_runs_conceded" integer DEFAULT 0 NOT NULL,
	"total_overs_bowled" numeric(6, 1) DEFAULT '0.0' NOT NULL,
	"position" integer,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_tournament_standings_tournament_team" UNIQUE("tournament_id","team_id")
);
--> statement-breakpoint
CREATE TABLE "tournament_teams" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tournament_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"group_name" varchar(10),
	"seed_number" integer,
	"joined_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "uq_tournament_teams_tournament_team" UNIQUE("tournament_id","team_id")
);
--> statement-breakpoint
CREATE TABLE "tournaments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(100) NOT NULL,
	"format" varchar(20) NOT NULL,
	"overs_per_match" integer NOT NULL,
	"ball_type_id" integer NOT NULL,
	"status" varchar(20) DEFAULT 'draft' NOT NULL,
	"points_win" integer DEFAULT 2 NOT NULL,
	"points_tie" integer DEFAULT 1 NOT NULL,
	"points_no_result" integer DEFAULT 1 NOT NULL,
	"points_loss" integer DEFAULT 0 NOT NULL,
	"num_groups" integer DEFAULT 1 NOT NULL,
	"qualify_per_group" integer DEFAULT 2 NOT NULL,
	"has_third_place_match" boolean DEFAULT false NOT NULL,
	"players_per_side" integer DEFAULT 11 NOT NULL,
	"max_overs_per_bowler" integer,
	"wide_runs" integer DEFAULT 1 NOT NULL,
	"no_ball_runs" integer DEFAULT 1 NOT NULL,
	"powerplay_overs" integer,
	"created_by" uuid NOT NULL,
	"start_date" date,
	"end_date" date,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "team_rosters" ADD CONSTRAINT "team_rosters_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "team_rosters" ADD CONSTRAINT "team_rosters_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "teams" ADD CONSTRAINT "teams_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_analytics" ADD CONSTRAINT "match_analytics_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_result" ADD CONSTRAINT "match_result_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_result" ADD CONSTRAINT "match_result_winner_team_id_teams_id_fk" FOREIGN KEY ("winner_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "match_result" ADD CONSTRAINT "match_result_man_of_match_id_users_id_fk" FOREIGN KEY ("man_of_match_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_home_team_id_teams_id_fk" FOREIGN KEY ("home_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_away_team_id_teams_id_fk" FOREIGN KEY ("away_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_ball_type_id_ball_types_id_fk" FOREIGN KEY ("ball_type_id") REFERENCES "public"."ball_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_toss_winner_id_teams_id_fk" FOREIGN KEY ("toss_winner_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_scorer_id_users_id_fk" FOREIGN KEY ("scorer_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "innings" ADD CONSTRAINT "innings_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "innings" ADD CONSTRAINT "innings_batting_team_id_teams_id_fk" FOREIGN KEY ("batting_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "innings" ADD CONSTRAINT "innings_bowling_team_id_teams_id_fk" FOREIGN KEY ("bowling_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "overs" ADD CONSTRAINT "overs_innings_id_innings_id_fk" FOREIGN KEY ("innings_id") REFERENCES "public"."innings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "overs" ADD CONSTRAINT "overs_bowler_id_users_id_fk" FOREIGN KEY ("bowler_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_innings_id_innings_id_fk" FOREIGN KEY ("innings_id") REFERENCES "public"."innings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_striker_id_users_id_fk" FOREIGN KEY ("striker_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_non_striker_id_users_id_fk" FOREIGN KEY ("non_striker_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_bowler_id_users_id_fk" FOREIGN KEY ("bowler_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "deliveries" ADD CONSTRAINT "deliveries_wagon_wheel_zone_id_wagon_wheel_zones_id_fk" FOREIGN KEY ("wagon_wheel_zone_id") REFERENCES "public"."wagon_wheel_zones"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fall_of_wickets" ADD CONSTRAINT "fall_of_wickets_innings_id_innings_id_fk" FOREIGN KEY ("innings_id") REFERENCES "public"."innings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fall_of_wickets" ADD CONSTRAINT "fall_of_wickets_dismissed_player_id_users_id_fk" FOREIGN KEY ("dismissed_player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fall_of_wickets" ADD CONSTRAINT "fall_of_wickets_delivery_id_deliveries_id_fk" FOREIGN KEY ("delivery_id") REFERENCES "public"."deliveries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wickets_by_delivery" ADD CONSTRAINT "wickets_by_delivery_delivery_id_deliveries_id_fk" FOREIGN KEY ("delivery_id") REFERENCES "public"."deliveries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wickets_by_delivery" ADD CONSTRAINT "wickets_by_delivery_dismissed_player_id_users_id_fk" FOREIGN KEY ("dismissed_player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wickets_by_delivery" ADD CONSTRAINT "wickets_by_delivery_dismissal_type_id_dismissal_types_id_fk" FOREIGN KEY ("dismissal_type_id") REFERENCES "public"."dismissal_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wickets_by_delivery" ADD CONSTRAINT "wickets_by_delivery_fielder_id_users_id_fk" FOREIGN KEY ("fielder_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batting_stats" ADD CONSTRAINT "batting_stats_innings_id_innings_id_fk" FOREIGN KEY ("innings_id") REFERENCES "public"."innings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batting_stats" ADD CONSTRAINT "batting_stats_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batting_stats" ADD CONSTRAINT "batting_stats_dismissal_type_id_dismissal_types_id_fk" FOREIGN KEY ("dismissal_type_id") REFERENCES "public"."dismissal_types"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batting_stats" ADD CONSTRAINT "batting_stats_dismissed_by_id_users_id_fk" FOREIGN KEY ("dismissed_by_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batting_stats" ADD CONSTRAINT "batting_stats_fielder_id_users_id_fk" FOREIGN KEY ("fielder_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bowling_stats" ADD CONSTRAINT "bowling_stats_innings_id_innings_id_fk" FOREIGN KEY ("innings_id") REFERENCES "public"."innings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bowling_stats" ADD CONSTRAINT "bowling_stats_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fielding_stats" ADD CONSTRAINT "fielding_stats_innings_id_innings_id_fk" FOREIGN KEY ("innings_id") REFERENCES "public"."innings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fielding_stats" ADD CONSTRAINT "fielding_stats_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "player_career_stats" ADD CONSTRAINT "player_career_stats_player_id_users_id_fk" FOREIGN KEY ("player_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_fixtures" ADD CONSTRAINT "tournament_fixtures_tournament_id_tournaments_id_fk" FOREIGN KEY ("tournament_id") REFERENCES "public"."tournaments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_fixtures" ADD CONSTRAINT "tournament_fixtures_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_fixtures" ADD CONSTRAINT "tournament_fixtures_home_team_id_teams_id_fk" FOREIGN KEY ("home_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_fixtures" ADD CONSTRAINT "tournament_fixtures_away_team_id_teams_id_fk" FOREIGN KEY ("away_team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_groups" ADD CONSTRAINT "tournament_groups_tournament_id_tournaments_id_fk" FOREIGN KEY ("tournament_id") REFERENCES "public"."tournaments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_requests" ADD CONSTRAINT "tournament_requests_tournament_id_tournaments_id_fk" FOREIGN KEY ("tournament_id") REFERENCES "public"."tournaments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_requests" ADD CONSTRAINT "tournament_requests_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_requests" ADD CONSTRAINT "tournament_requests_requested_by_users_id_fk" FOREIGN KEY ("requested_by") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_standings" ADD CONSTRAINT "tournament_standings_tournament_id_tournaments_id_fk" FOREIGN KEY ("tournament_id") REFERENCES "public"."tournaments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_standings" ADD CONSTRAINT "tournament_standings_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_teams" ADD CONSTRAINT "tournament_teams_tournament_id_tournaments_id_fk" FOREIGN KEY ("tournament_id") REFERENCES "public"."tournaments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournament_teams" ADD CONSTRAINT "tournament_teams_team_id_teams_id_fk" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournaments" ADD CONSTRAINT "tournaments_ball_type_id_ball_types_id_fk" FOREIGN KEY ("ball_type_id") REFERENCES "public"."ball_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tournaments" ADD CONSTRAINT "tournaments_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_rosters_team" ON "team_rosters" USING btree ("team_id");--> statement-breakpoint
CREATE INDEX "idx_rosters_player" ON "team_rosters" USING btree ("player_id");--> statement-breakpoint
CREATE INDEX "idx_match_players_match" ON "match_players" USING btree ("match_id");--> statement-breakpoint
CREATE INDEX "idx_match_players_team" ON "match_players" USING btree ("match_id","team_id");--> statement-breakpoint
CREATE INDEX "idx_match_players_player" ON "match_players" USING btree ("player_id");--> statement-breakpoint
CREATE INDEX "idx_matches_status" ON "matches" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_matches_teams" ON "matches" USING btree ("home_team_id","away_team_id");--> statement-breakpoint
CREATE INDEX "idx_matches_tournament" ON "matches" USING btree ("tournament_id") WHERE tournament_id IS NOT NULL;--> statement-breakpoint
CREATE INDEX "idx_deliveries_innings" ON "deliveries" USING btree ("innings_id");--> statement-breakpoint
CREATE INDEX "idx_deliveries_bowler" ON "deliveries" USING btree ("bowler_id");--> statement-breakpoint
CREATE INDEX "idx_deliveries_striker" ON "deliveries" USING btree ("striker_id");--> statement-breakpoint
CREATE INDEX "idx_deliveries_over" ON "deliveries" USING btree ("innings_id","over_number");--> statement-breakpoint
CREATE INDEX "idx_deliveries_synced" ON "deliveries" USING btree ("synced") WHERE synced = false;--> statement-breakpoint
CREATE INDEX "idx_deliveries_sequence" ON "deliveries" USING btree ("innings_id","sequence_number");--> statement-breakpoint
CREATE INDEX "idx_batting_stats_innings" ON "batting_stats" USING btree ("innings_id");--> statement-breakpoint
CREATE INDEX "idx_batting_stats_player" ON "batting_stats" USING btree ("player_id");--> statement-breakpoint
CREATE INDEX "idx_bowling_stats_innings" ON "bowling_stats" USING btree ("innings_id");--> statement-breakpoint
CREATE INDEX "idx_bowling_stats_player" ON "bowling_stats" USING btree ("player_id");--> statement-breakpoint
CREATE INDEX "idx_career_stats_player" ON "player_career_stats" USING btree ("player_id","format");--> statement-breakpoint
CREATE INDEX "idx_tournament_fixtures_tournament" ON "tournament_fixtures" USING btree ("tournament_id");--> statement-breakpoint
CREATE INDEX "idx_tournament_fixtures_match" ON "tournament_fixtures" USING btree ("match_id");--> statement-breakpoint
CREATE INDEX "idx_tournament_requests_tournament" ON "tournament_requests" USING btree ("tournament_id");--> statement-breakpoint
CREATE INDEX "idx_tournament_requests_status" ON "tournament_requests" USING btree ("tournament_id","status");--> statement-breakpoint
CREATE INDEX "idx_tournament_standings_tournament" ON "tournament_standings" USING btree ("tournament_id");--> statement-breakpoint
CREATE INDEX "idx_tournament_standings_group" ON "tournament_standings" USING btree ("tournament_id","group_name");--> statement-breakpoint
CREATE INDEX "idx_tournament_teams_tournament" ON "tournament_teams" USING btree ("tournament_id");--> statement-breakpoint
CREATE INDEX "idx_tournament_teams_team" ON "tournament_teams" USING btree ("team_id");--> statement-breakpoint
CREATE INDEX "idx_tournaments_status" ON "tournaments" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_tournaments_creator" ON "tournaments" USING btree ("created_by");