CREATE TABLE `nitro_history_histories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `source_type` varchar(191) DEFAULT NULL,
  `source_id` varchar(191) DEFAULT NULL,
  `source_changes` text,
  `created_at` datetime DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `note` text,
  `activity` varchar(191) DEFAULT NULL,
  `encrypted_note` text,
  `backtrace` text,
  PRIMARY KEY (`id`),
  KEY `index_nitro_history_histories_on_source_type_and_source_id` (`source_type`,`source_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `schema_migrations` VALUES
('20161014175106'),
('20161017134603'),
('20161017145713'),
('20161017160533'),
('20190723124451'),
('20190729160855'),
('20200514201449');
