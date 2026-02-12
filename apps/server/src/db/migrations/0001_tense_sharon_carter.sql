ALTER TABLE "ball_types" ADD CONSTRAINT "ball_types_name_unique" UNIQUE("name");--> statement-breakpoint
ALTER TABLE "dismissal_types" ADD CONSTRAINT "dismissal_types_name_unique" UNIQUE("name");--> statement-breakpoint
ALTER TABLE "fielding_positions" ADD CONSTRAINT "fielding_positions_name_unique" UNIQUE("name");--> statement-breakpoint
ALTER TABLE "wagon_wheel_zones" ADD CONSTRAINT "wagon_wheel_zones_zone_code_unique" UNIQUE("zone_code");