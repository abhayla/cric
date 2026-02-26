ALTER TABLE "activity_feed" ADD COLUMN "delivery_id" uuid REFERENCES "deliveries"("id") ON DELETE SET NULL;
CREATE INDEX "idx_activity_feed_delivery" ON "activity_feed" ("delivery_id");
