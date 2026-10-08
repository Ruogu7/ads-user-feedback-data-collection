-- 智能驾驶体验调研系统数据库结构（MySQL 8.0+）
CREATE DATABASE IF NOT EXISTS ads_survey DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ads_survey;

CREATE TABLE survey_version (
  version_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  version_code VARCHAR(20) NOT NULL UNIQUE,
  version_name VARCHAR(120) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'draft',
  published_at DATETIME NULL,
  version_note VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_version_status (status, published_at)
) ENGINE=InnoDB;

CREATE TABLE survey_question (
  question_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  version_id BIGINT UNSIGNED NOT NULL,
  section_code VARCHAR(40) NOT NULL,
  question_code VARCHAR(40) NOT NULL,
  question_text VARCHAR(1000) NOT NULL,
  question_type VARCHAR(30) NOT NULL,
  is_required TINYINT(1) NOT NULL DEFAULT 0,
  sort_no INT NOT NULL DEFAULT 0,
  options_json JSON NULL,
  question_config_json JSON NULL,
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_question_version_code (version_id, question_code),
  INDEX idx_question_section_sort (version_id, section_code, sort_no),
  CONSTRAINT fk_question_version FOREIGN KEY (version_id) REFERENCES survey_version(version_id)
) ENGINE=InnoDB;

CREATE TABLE survey_response (
  record_id VARCHAR(32) PRIMARY KEY,
  version_id BIGINT UNSIGNED NOT NULL,
  submitted_at DATETIME NOT NULL,
  validity_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  review_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  source_channel VARCHAR(30) NULL,
  province VARCHAR(50) NULL,
  city VARCHAR(50) NULL,
  district VARCHAR(80) NULL,
  brand_name VARCHAR(100) NULL,
  vehicle_model VARCHAR(100) NULL,
  vehicle_power_type VARCHAR(20) NULL,
  vehicle_purchase_year SMALLINT NULL,
  has_smart_driving VARCHAR(10) NULL,
  smart_driving_experience_months INT NULL,
  functions_used TEXT NULL,
  purchase_decision_factor VARCHAR(100) NULL,
  usage_frequency VARCHAR(30) NULL,
  trust_score_1_5 TINYINT NULL,
  system_safety_score_1_5 TINYINT NULL,
  function_safety_score_1_5 TINYINT NULL,
  information_safety_score_1_5 TINYINT NULL,
  privacy_concern_level VARCHAR(20) NULL,
  failure_event_flag VARCHAR(10) NULL,
  failure_event_type VARCHAR(100) NULL,
  failure_description TEXT NULL,
  expected_features TEXT NULL,
  policy_expectation TEXT NULL,
  followup_consent VARCHAR(10) NOT NULL DEFAULT '否',
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_response_submitted (submitted_at),
  INDEX idx_response_validity (validity_status, review_status),
  INDEX idx_response_region_brand (province, city, brand_name),
  CONSTRAINT fk_response_version FOREIGN KEY (version_id) REFERENCES survey_version(version_id),
  CONSTRAINT ck_response_scores CHECK (trust_score_1_5 IS NULL OR trust_score_1_5 BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE survey_answer (
  answer_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  record_id VARCHAR(32) NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  answer_option VARCHAR(255) NULL,
  answer_text TEXT NULL,
  answer_number DECIMAL(12,4) NULL,
  answer_json JSON NULL,
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_response_question (record_id, question_id),
  INDEX idx_answer_question (question_id),
  CONSTRAINT fk_answer_response FOREIGN KEY (record_id) REFERENCES survey_response(record_id),
  CONSTRAINT fk_answer_question FOREIGN KEY (question_id) REFERENCES survey_question(question_id)
) ENGINE=InnoDB;

CREATE TABLE risk_event (
  risk_event_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  record_id VARCHAR(32) NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  severity VARCHAR(20) NULL,
  event_description TEXT NULL,
  occurred_at DATETIME NULL,
  review_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  review_note VARCHAR(1000) NULL,
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_risk_record_status (record_id, review_status),
  CONSTRAINT fk_risk_response FOREIGN KEY (record_id) REFERENCES survey_response(record_id)
) ENGINE=InnoDB;

CREATE TABLE followup_contact (
  contact_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  record_id VARCHAR(32) NOT NULL UNIQUE,
  consent VARCHAR(10) NOT NULL,
  email_ciphertext VARBINARY(512) NULL,
  email_hash CHAR(64) NULL,
  contact_status VARCHAR(20) NOT NULL DEFAULT 'available',
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_followup_response FOREIGN KEY (record_id) REFERENCES survey_response(record_id),
  INDEX idx_followup_consent (consent, created_at)
) ENGINE=InnoDB;

CREATE TABLE data_review_log (
  review_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  record_id VARCHAR(32) NOT NULL,
  reviewer_id BIGINT UNSIGNED NULL,
  action VARCHAR(30) NOT NULL,
  old_status VARCHAR(20) NULL,
  new_status VARCHAR(20) NULL,
  review_note VARCHAR(1000) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_review_record_time (record_id, created_at),
  CONSTRAINT fk_review_response FOREIGN KEY (record_id) REFERENCES survey_response(record_id)
) ENGINE=InnoDB;

CREATE TABLE team_member (
  team_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  team_name VARCHAR(120) NOT NULL,
  team_role VARCHAR(120) NULL,
  profile_text TEXT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE admin_user (
  admin_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  team_id BIGINT UNSIGNED NULL,
  account VARCHAR(120) NOT NULL UNIQUE,
  display_name VARCHAR(120) NOT NULL,
  role_code VARCHAR(40) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  reserved_text_01 VARCHAR(255) NULL,
  reserved_text_02 VARCHAR(255) NULL,
  reserved_text_03 VARCHAR(255) NULL,
  reserved_text_04 VARCHAR(255) NULL,
  reserved_text_05 VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_admin_team FOREIGN KEY (team_id) REFERENCES team_member(team_id)
) ENGINE=InnoDB;

CREATE TABLE export_job (
  export_job_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  created_by BIGINT UNSIGNED NULL,
  export_scope VARCHAR(30) NOT NULL,
  filter_json JSON NULL,
  file_name VARCHAR(255) NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'queued',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  CONSTRAINT fk_export_admin FOREIGN KEY (created_by) REFERENCES admin_user(admin_id),
  INDEX idx_export_status_time (status, created_at)
) ENGINE=InnoDB;

-- 最终导出建议：仅导出 validity_status='valid' 的 survey_response，且不联结 followup_contact.email_ciphertext。
CREATE VIEW v_valid_survey_export AS
SELECT r.*
FROM survey_response r
WHERE r.validity_status = 'valid';
