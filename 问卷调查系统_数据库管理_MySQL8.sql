-- 智能驾驶汽车用户调研问卷系统
-- 数据库：MySQL 8.0+
-- 编码：utf8mb4
-- 说明：脚本不删除既有数据库或表，可用于首次建库和重复校验。

CREATE DATABASE IF NOT EXISTS ads_survey
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE ads_survey;

-- 1. 账户、角色与权限
CREATE TABLE IF NOT EXISTS app_user (
  user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '账户主键',
  login_name VARCHAR(80) NOT NULL COMMENT '登录名',
  password_hash VARCHAR(255) NOT NULL COMMENT '口令哈希，推荐 Argon2id 或 bcrypt',
  display_name VARCHAR(80) NULL COMMENT '显示名称',
  account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE LOCKED DISABLED',
  last_login_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL COMMENT '软删除时间',
  PRIMARY KEY (user_id),
  UNIQUE KEY uk_app_user_login_name (login_name),
  CONSTRAINT ck_app_user_status CHECK (account_status IN ('ACTIVE','LOCKED','DISABLED'))
) ENGINE=InnoDB COMMENT='系统账户，不存放主答卷内容';

CREATE TABLE IF NOT EXISTS app_role (
  role_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_code VARCHAR(40) NOT NULL COMMENT 'ADMIN ANALYST AUDITOR',
  role_name VARCHAR(80) NOT NULL,
  role_description VARCHAR(255) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (role_id),
  UNIQUE KEY uk_app_role_code (role_code)
) ENGINE=InnoDB COMMENT='角色定义';

CREATE TABLE IF NOT EXISTS app_user_role (
  user_id BIGINT UNSIGNED NOT NULL,
  role_id SMALLINT UNSIGNED NOT NULL,
  granted_by BIGINT UNSIGNED NULL,
  granted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES app_user(user_id),
  CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES app_role(role_id),
  CONSTRAINT fk_user_role_grantor FOREIGN KEY (granted_by) REFERENCES app_user(user_id)
) ENGINE=InnoDB COMMENT='账户角色关系';

-- 2. 问卷定义与版本
CREATE TABLE IF NOT EXISTS survey (
  survey_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  survey_code VARCHAR(40) NOT NULL COMMENT '稳定业务编码',
  survey_name VARCHAR(160) NOT NULL,
  survey_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT PUBLISHED CLOSED',
  owner_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (survey_id),
  UNIQUE KEY uk_survey_code (survey_code),
  CONSTRAINT fk_survey_owner FOREIGN KEY (owner_user_id) REFERENCES app_user(user_id),
  CONSTRAINT ck_survey_status CHECK (survey_status IN ('DRAFT','PUBLISHED','CLOSED'))
) ENGINE=InnoDB COMMENT='问卷主表';

CREATE TABLE IF NOT EXISTS survey_version (
  survey_version_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  survey_id BIGINT UNSIGNED NOT NULL,
  version_no VARCHAR(30) NOT NULL COMMENT '如 V1.0',
  version_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  title VARCHAR(200) NOT NULL,
  introduction TEXT NULL,
  privacy_notice TEXT NULL,
  published_at DATETIME(3) NULL,
  closed_at DATETIME(3) NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (survey_version_id),
  UNIQUE KEY uk_survey_version (survey_id, version_no),
  CONSTRAINT fk_version_survey FOREIGN KEY (survey_id) REFERENCES survey(survey_id),
  CONSTRAINT fk_version_creator FOREIGN KEY (created_by) REFERENCES app_user(user_id),
  CONSTRAINT ck_version_status CHECK (version_status IN ('DRAFT','PUBLISHED','CLOSED','ARCHIVED'))
) ENGINE=InnoDB COMMENT='问卷版本，已发布版本原则上只读';

CREATE TABLE IF NOT EXISTS survey_section (
  section_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  survey_version_id BIGINT UNSIGNED NOT NULL,
  section_code VARCHAR(30) NOT NULL,
  section_title VARCHAR(160) NOT NULL,
  section_description VARCHAR(500) NULL,
  display_order INT UNSIGNED NOT NULL,
  visibility_rule_json JSON NULL COMMENT '分支显示规则',
  PRIMARY KEY (section_id),
  UNIQUE KEY uk_section_code (survey_version_id, section_code),
  KEY idx_section_order (survey_version_id, display_order),
  CONSTRAINT fk_section_version FOREIGN KEY (survey_version_id) REFERENCES survey_version(survey_version_id)
) ENGINE=InnoDB COMMENT='问卷章节';

CREATE TABLE IF NOT EXISTS survey_question (
  question_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  section_id BIGINT UNSIGNED NOT NULL,
  question_code VARCHAR(20) NOT NULL COMMENT '发布版本内稳定题号，如 Q01',
  question_type VARCHAR(30) NOT NULL COMMENT 'SINGLE MULTIPLE MATRIX TEXT NUMBER REGION CONSENT',
  question_text TEXT NOT NULL,
  help_text VARCHAR(1000) NULL,
  is_required TINYINT(1) NOT NULL DEFAULT 0,
  max_selections SMALLINT UNSIGNED NULL,
  max_length SMALLINT UNSIGNED NULL,
  display_order INT UNSIGNED NOT NULL,
  validation_json JSON NULL,
  branching_json JSON NULL,
  analysis_tag VARCHAR(80) NULL COMMENT '构念或统计标签',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (question_id),
  UNIQUE KEY uk_question_code (section_id, question_code),
  KEY idx_question_order (section_id, display_order),
  CONSTRAINT fk_question_section FOREIGN KEY (section_id) REFERENCES survey_section(section_id),
  CONSTRAINT ck_question_type CHECK (question_type IN ('SINGLE','MULTIPLE','RANKING','MATRIX','TEXT','NUMBER','REGION','CONSENT'))
) ENGINE=InnoDB COMMENT='问题定义';

CREATE TABLE IF NOT EXISTS question_option (
  option_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  question_id BIGINT UNSIGNED NOT NULL,
  option_code VARCHAR(30) NOT NULL,
  option_label VARCHAR(500) NOT NULL,
  option_value VARCHAR(120) NOT NULL,
  display_order INT UNSIGNED NOT NULL,
  is_other TINYINT(1) NOT NULL DEFAULT 0,
  is_exclusive TINYINT(1) NOT NULL DEFAULT 0 COMMENT '如“没有”“不适用”',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (option_id),
  UNIQUE KEY uk_question_option (question_id, option_code),
  KEY idx_option_order (question_id, display_order),
  CONSTRAINT fk_option_question FOREIGN KEY (question_id) REFERENCES survey_question(question_id)
) ENGINE=InnoDB COMMENT='题目选项';

-- 3. 匿名主答卷与答案
CREATE TABLE IF NOT EXISTS survey_response (
  response_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  response_no VARCHAR(32) NOT NULL COMMENT '展示编号，如 RSP-104862',
  survey_version_id BIGINT UNSIGNED NOT NULL,
  respondent_key CHAR(36) NOT NULL COMMENT '匿名随机标识，不使用姓名或手机号',
  response_status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS' COMMENT 'IN_PROGRESS SUBMITTED VALID REVIEW REJECTED',
  completion_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  region_province_code VARCHAR(20) NULL,
  region_city_code VARCHAR(20) NULL,
  started_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  submitted_at DATETIME(3) NULL,
  reviewed_at DATETIME(3) NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  client_fingerprint_hash CHAR(64) NULL COMMENT '仅保存不可逆摘要，按合规策略启用',
  source_channel VARCHAR(40) NULL,
  risk_level VARCHAR(20) NOT NULL DEFAULT 'NONE' COMMENT 'NONE LOW MEDIUM HIGH',
  -- 明确预留 5 个字符型字段，供后续需求变化使用。
  reserved_char_01 VARCHAR(255) NULL COMMENT '预留字符字段1',
  reserved_char_02 VARCHAR(255) NULL COMMENT '预留字符字段2',
  reserved_char_03 VARCHAR(255) NULL COMMENT '预留字符字段3',
  reserved_char_04 VARCHAR(255) NULL COMMENT '预留字符字段4',
  reserved_char_05 VARCHAR(255) NULL COMMENT '预留字符字段5',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (response_id),
  UNIQUE KEY uk_response_no (response_no),
  UNIQUE KEY uk_response_respondent (survey_version_id, respondent_key),
  KEY idx_response_status_time (response_status, submitted_at),
  KEY idx_response_region (region_province_code, region_city_code),
  KEY idx_response_risk (risk_level, submitted_at),
  CONSTRAINT fk_response_version FOREIGN KEY (survey_version_id) REFERENCES survey_version(survey_version_id),
  CONSTRAINT fk_response_reviewer FOREIGN KEY (reviewed_by) REFERENCES app_user(user_id),
  CONSTRAINT ck_response_status CHECK (response_status IN ('IN_PROGRESS','SUBMITTED','VALID','REVIEW','REJECTED')),
  CONSTRAINT ck_response_risk CHECK (risk_level IN ('NONE','LOW','MEDIUM','HIGH')),
  CONSTRAINT ck_response_completion CHECK (completion_percent BETWEEN 0 AND 100)
) ENGINE=InnoDB COMMENT='匿名主答卷；5个VARCHAR预留字段位于本表';

CREATE TABLE IF NOT EXISTS survey_answer (
  answer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  response_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  answer_text TEXT NULL COMMENT '开放题或单值文本',
  answer_number DECIMAL(18,4) NULL,
  answer_json JSON NULL COMMENT '多选、排序、矩阵答案',
  is_skipped TINYINT(1) NOT NULL DEFAULT 0,
  answered_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (answer_id),
  UNIQUE KEY uk_answer_response_question (response_id, question_id),
  KEY idx_answer_question (question_id),
  CONSTRAINT fk_answer_response FOREIGN KEY (response_id) REFERENCES survey_response(response_id),
  CONSTRAINT fk_answer_question FOREIGN KEY (question_id) REFERENCES survey_question(question_id)
) ENGINE=InnoDB COMMENT='答题结果；一种题型使用一个主要答案列';

CREATE TABLE IF NOT EXISTS incident_detail (
  incident_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  response_id BIGINT UNSIGNED NOT NULL,
  incident_time_bucket VARCHAR(30) NULL,
  function_code VARCHAR(50) NULL,
  severity_code VARCHAR(30) NULL,
  prompt_quality_code VARCHAR(30) NULL,
  resolution_code VARCHAR(30) NULL,
  narrative_text VARCHAR(1000) NULL COMMENT '开放描述，前端限制200字，数据库留足审校空间',
  pii_review_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING PASS MASKED',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (incident_id),
  KEY idx_incident_severity (severity_code, created_at),
  CONSTRAINT fk_incident_response FOREIGN KEY (response_id) REFERENCES survey_response(response_id),
  CONSTRAINT ck_incident_pii CHECK (pii_review_status IN ('PENDING','PASS','MASKED'))
) ENGINE=InnoDB COMMENT='风险事件结构化明细';

-- 4. 自愿回访信息：与主答卷物理分表，并限制权限
CREATE TABLE IF NOT EXISTS followup_contact (
  contact_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  response_id BIGINT UNSIGNED NOT NULL,
  contact_alias VARCHAR(80) NULL,
  phone_ciphertext VARBINARY(512) NULL COMMENT '应用层加密后的手机号',
  email_ciphertext VARBINARY(512) NULL COMMENT '应用层加密后的邮箱',
  contact_type VARCHAR(20) NOT NULL COMMENT 'PHONE EMAIL BOTH',
  consent_status VARCHAR(20) NOT NULL DEFAULT 'GRANTED' COMMENT 'GRANTED WITHDRAWN EXPIRED',
  consented_at DATETIME(3) NOT NULL,
  consent_expires_at DATETIME(3) NULL,
  withdrawn_at DATETIME(3) NULL,
  max_contact_times SMALLINT UNSIGNED NULL,
  contact_purpose VARCHAR(255) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (contact_id),
  UNIQUE KEY uk_followup_response (response_id),
  KEY idx_followup_consent (consent_status, consent_expires_at),
  CONSTRAINT fk_followup_response FOREIGN KEY (response_id) REFERENCES survey_response(response_id),
  CONSTRAINT ck_followup_type CHECK (contact_type IN ('PHONE','EMAIL','BOTH')),
  CONSTRAINT ck_followup_consent CHECK (consent_status IN ('GRANTED','WITHDRAWN','EXPIRED'))
) ENGINE=InnoDB COMMENT='回访联系方式，与主答卷分表加密保存';

-- 5. 管理员补充字段及字段值
CREATE TABLE IF NOT EXISTS custom_field_definition (
  field_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  survey_id BIGINT UNSIGNED NOT NULL,
  field_code VARCHAR(60) NOT NULL,
  field_name VARCHAR(120) NOT NULL,
  data_type VARCHAR(20) NOT NULL DEFAULT 'VARCHAR' COMMENT 'VARCHAR NUMBER DATE BOOLEAN',
  max_length INT UNSIGNED NULL,
  field_description VARCHAR(500) NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (field_id),
  UNIQUE KEY uk_custom_field (survey_id, field_code),
  CONSTRAINT fk_custom_field_survey FOREIGN KEY (survey_id) REFERENCES survey(survey_id),
  CONSTRAINT fk_custom_field_creator FOREIGN KEY (created_by) REFERENCES app_user(user_id),
  CONSTRAINT ck_custom_field_type CHECK (data_type IN ('VARCHAR','NUMBER','DATE','BOOLEAN'))
) ENGINE=InnoDB COMMENT='管理员定义的扩展字段元数据';

CREATE TABLE IF NOT EXISTS response_custom_field (
  response_id BIGINT UNSIGNED NOT NULL,
  field_id BIGINT UNSIGNED NOT NULL,
  value_text VARCHAR(2000) NULL,
  value_number DECIMAL(18,4) NULL,
  value_date DATE NULL,
  value_boolean TINYINT(1) NULL,
  updated_by BIGINT UNSIGNED NULL,
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (response_id, field_id),
  CONSTRAINT fk_custom_value_response FOREIGN KEY (response_id) REFERENCES survey_response(response_id),
  CONSTRAINT fk_custom_value_field FOREIGN KEY (field_id) REFERENCES custom_field_definition(field_id),
  CONSTRAINT fk_custom_value_editor FOREIGN KEY (updated_by) REFERENCES app_user(user_id)
) ENGINE=InnoDB COMMENT='管理员补充字段值';

-- 6. 导出任务与审计日志
CREATE TABLE IF NOT EXISTS export_task (
  export_task_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  requested_by BIGINT UNSIGNED NOT NULL,
  survey_version_id BIGINT UNSIGNED NOT NULL,
  filter_json JSON NULL,
  export_format VARCHAR(20) NOT NULL DEFAULT 'CSV',
  mask_contact_data TINYINT(1) NOT NULL DEFAULT 1,
  task_status VARCHAR(20) NOT NULL DEFAULT 'QUEUED',
  object_key VARCHAR(500) NULL COMMENT '导出文件对象存储键，不保存公网URL',
  expires_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  finished_at DATETIME(3) NULL,
  PRIMARY KEY (export_task_id),
  KEY idx_export_status (task_status, created_at),
  CONSTRAINT fk_export_requester FOREIGN KEY (requested_by) REFERENCES app_user(user_id),
  CONSTRAINT fk_export_version FOREIGN KEY (survey_version_id) REFERENCES survey_version(survey_version_id),
  CONSTRAINT ck_export_format CHECK (export_format IN ('CSV','XLSX','JSON')),
  CONSTRAINT ck_export_status CHECK (task_status IN ('QUEUED','RUNNING','SUCCEEDED','FAILED','EXPIRED'))
) ENGINE=InnoDB COMMENT='异步脱敏导出任务';

CREATE TABLE IF NOT EXISTS admin_audit_log (
  audit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_user_id BIGINT UNSIGNED NULL,
  action_code VARCHAR(80) NOT NULL,
  object_type VARCHAR(50) NOT NULL,
  object_id VARCHAR(80) NULL,
  before_json JSON NULL,
  after_json JSON NULL,
  request_id VARCHAR(64) NULL,
  ip_hash CHAR(64) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (audit_id),
  KEY idx_audit_actor_time (actor_user_id, created_at),
  KEY idx_audit_object (object_type, object_id, created_at),
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES app_user(user_id)
) ENGINE=InnoDB COMMENT='管理员操作审计，建议只追加不更新';

-- 7. 便于管理员查看的脱敏视图
CREATE OR REPLACE VIEW v_response_overview AS
SELECT
  r.response_id,
  r.response_no,
  r.survey_version_id,
  r.response_status,
  r.completion_percent,
  r.region_province_code,
  r.region_city_code,
  r.risk_level,
  r.started_at,
  r.submitted_at,
  r.reviewed_at,
  r.reserved_char_01,
  r.reserved_char_02,
  r.reserved_char_03,
  r.reserved_char_04,
  r.reserved_char_05,
  COUNT(a.answer_id) AS answered_question_count
FROM survey_response r
LEFT JOIN survey_answer a ON a.response_id = r.response_id
WHERE r.deleted_at IS NULL
GROUP BY
  r.response_id, r.response_no, r.survey_version_id, r.response_status,
  r.completion_percent, r.region_province_code, r.region_city_code,
  r.risk_level, r.started_at, r.submitted_at, r.reviewed_at,
  r.reserved_char_01, r.reserved_char_02, r.reserved_char_03,
  r.reserved_char_04, r.reserved_char_05;

-- 8. 初始角色（幂等）
INSERT INTO app_role (role_code, role_name, role_description)
VALUES
  ('ADMIN', '系统管理员', '管理问卷、账户、字段与导出权限'),
  ('ANALYST', '数据分析员', '查看脱敏答卷并执行统计分析'),
  ('AUDITOR', '审计员', '只读查看审计日志与导出记录')
ON DUPLICATE KEY UPDATE
  role_name = VALUES(role_name),
  role_description = VALUES(role_description);

-- 9. 常用管理语句示例（按需执行）
-- 统计月度累计提交：
-- SELECT DATE_FORMAT(submitted_at, '%Y-%m') AS month_key, COUNT(*) AS response_count
-- FROM survey_response
-- WHERE response_status IN ('SUBMITTED','VALID','REVIEW') AND deleted_at IS NULL
-- GROUP BY DATE_FORMAT(submitted_at, '%Y-%m') ORDER BY month_key;

-- 查看高风险待复核记录：
-- SELECT response_no, region_province_code, region_city_code, submitted_at
-- FROM survey_response
-- WHERE risk_level = 'HIGH' AND response_status = 'REVIEW' AND deleted_at IS NULL
-- ORDER BY submitted_at DESC LIMIT 100;

-- 启用预留字符字段的示例：
-- UPDATE survey_response SET reserved_char_01 = '人工复核批次A' WHERE response_id = 1001;

-- 撤回回访同意：
-- UPDATE followup_contact
-- SET consent_status = 'WITHDRAWN', withdrawn_at = CURRENT_TIMESTAMP(3)
-- WHERE response_id = 1001 AND consent_status = 'GRANTED';

