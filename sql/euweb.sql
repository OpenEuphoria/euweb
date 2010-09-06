-- MySQL dump 10.11
--
-- Host: localhost    Database: database_name
-- ------------------------------------------------------
-- Server version	5.0.75-0ubuntu10.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `database_name`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `euweb` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `euweb`;

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `comment` (
  `id` int(11) NOT NULL auto_increment,
  `module_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `subject` varchar(255) NOT NULL,
  `body` text NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `link_idx` (`module_id`,`item_id`),
  KEY `natural_display_idx` (`module_id`,`item_id`,`created_at`)
) ENGINE=MyISAM AUTO_INCREMENT=447 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `comment`
--

LOCK TABLES `comment` WRITE;
/*!40000 ALTER TABLE `comment` DISABLE KEYS */;
/*!40000 ALTER TABLE `comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ip_requests`
--

DROP TABLE IF EXISTS `ip_requests`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ip_requests` (
  `ip` varchar(15) NOT NULL,
  `request_date` datetime NOT NULL,
  `url` text,
  KEY `find_banned` (`ip`,`request_date`)
) ENGINE=MyISAM DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ip_requests`
--

LOCK TABLES `ip_requests` WRITE;
/*!40000 ALTER TABLE `ip_requests` DISABLE KEYS */;
INSERT INTO `ip_requests` VALUES ('UNKNOWN','2010-02-21 19:10:45','[?] ???'),('UNKNOWN','2010-02-21 19:19:55','[?] ???'),('UNKNOWN','2010-02-21 19:27:04','[?] ???'),('UNKNOWN','2010-02-21 19:27:52','[?] ???'),('UNKNOWN','2010-02-21 19:28:46','[?] ???'),('UNKNOWN','2010-02-21 19:34:00','[?] ???');
/*!40000 ALTER TABLE `ip_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `messages` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `parent_id` int(11) default '0',
  `author_name` varchar(80) NOT NULL default '',
  `author_email` varchar(128) default NULL,
  `subject` varchar(128) NOT NULL default '',
  `body` mediumtext NOT NULL,
  `views` int(11) NOT NULL default '0',
  `ip` varchar(32) NOT NULL default '0.0.0.0',
  `last_post_id` int(11) default '0',
  `replies` int(11) default '0',
  `last_post_by` varchar(80) default '',
  `last_post_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `last_post_by_id` int(11) default '0',
  `post_by` int(11) default '0',
  `topic_id` int(11) NOT NULL default '0',
  `last_edit_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `messages_parent_id_idx` (`parent_id`),
  KEY `messages_thread_view_idx` (`parent_id`,`last_post_at`),
  KEY `messages_last_post_idx` (`last_post_at`),
  KEY `messages_created_at_idx` (`created_at`),
  KEY `topic_list` (`last_post_at`,`parent_id`),
  KEY `created` (`created_at`),
  FULLTEXT KEY `subject` (`subject`,`body`)
) ENGINE=MyISAM AUTO_INCREMENT=111010 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (110997,'2010-03-13 20:20:11',0,'UserB','UserB@UserB.tld','yay new users can now post to this forum, starting today','I just fixed a bug in edbi that caused the crash that led to new users 1) seeing an error page instead of the successful signup page and 2) lead to new users not getting assigned the user role (which lead to new users being unable to make new ports).\r\n',29,'0.0.0.0',111000,2,'UserB','2010-03-13 21:10:29',372,372,110997,'2010-03-13 20:20:11');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `news`
--

DROP TABLE IF EXISTS `news`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `news` (
  `id` int(11) NOT NULL auto_increment,
  `submitted_by_id` int(11) NOT NULL,
  `approved` tinyint(4) NOT NULL default '0',
  `approved_by_id` int(11) NOT NULL,
  `publish_at` datetime NOT NULL,
  `subject` varchar(128) NOT NULL,
  `content` mediumtext NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `news_display_order_idx` (`publish_at`,`approved`),
  KEY `created` (`publish_at`),
  FULLTEXT KEY `subject` (`subject`,`content`)
) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `news`
--

LOCK TABLES `news` WRITE;
/*!40000 ALTER TABLE `news` DISABLE KEYS */;
INSERT INTO `news` VALUES (8,372,1,372,'2010-03-13 20:28:25','test','This is a test post. I guess at this point the test forum is officially up and running....\r\n');
/*!40000 ALTER TABLE `news` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `people`
--

DROP TABLE IF EXISTS `people`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `people` (
  `name` varchar(30) default NULL,
  `zip` int(11) default NULL,
  `dob` datetime default NULL
) ENGINE=MyISAM DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `people`
--

LOCK TABLES `people` WRITE;
/*!40000 ALTER TABLE `people` DISABLE KEYS */;
/*!40000 ALTER TABLE `people` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `read_messages`
--

DROP TABLE IF EXISTS `read_messages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `read_messages` (
  `ip` varchar(32) NOT NULL default '',
  `message_id` int(11) NOT NULL default '0',
  `userid` int(11) default '0',
  KEY `read_messages_idx` (`userid`,`message_id`,`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `read_messages`
--

LOCK TABLES `read_messages` WRITE;
/*!40000 ALTER TABLE `read_messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `read_messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `releases`
--

DROP TABLE IF EXISTS `releases`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `releases` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL,
  `archived` int(11) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `releases`
--

LOCK TABLES `releases` WRITE;
/*!40000 ALTER TABLE `releases` DISABLE KEYS */;
/*!40000 ALTER TABLE `releases` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `session` (
  `sess_id` varchar(32) NOT NULL default '',
  `key` text NOT NULL,
  `value` text NOT NULL,
  PRIMARY KEY  (`sess_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `session`
--

LOCK TABLES `session` WRITE;
/*!40000 ALTER TABLE `session` DISABLE KEYS */;
/*!40000 ALTER TABLE `session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket`
--

DROP TABLE IF EXISTS `ticket`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime NOT NULL,
  `submitted_by_id` int(11) NOT NULL,
  `assigned_to_id` int(11) NOT NULL,
  `severity_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `status_id` int(11) NOT NULL,
  `state_id` int(11) NOT NULL,
  `subject` varchar(120) NOT NULL,
  `content` mediumtext NOT NULL,
  `resolved_at` datetime default NULL,
  `svn_rev` varchar(60) default NULL,
  `reported_release` varchar(30) NOT NULL default '',
  `product_id` int(11) NOT NULL default '1',
  `type_id` int(11) NOT NULL default '1',
  PRIMARY KEY  (`id`),
  KEY `created` (`created_at`),
  FULLTEXT KEY `subject` (`subject`,`content`)
) ENGINE=MyISAM AUTO_INCREMENT=136 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket`
--

LOCK TABLES `ticket` WRITE;
/*!40000 ALTER TABLE `ticket` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_category`
--

DROP TABLE IF EXISTS `ticket_category`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket_category` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket_category`
--

LOCK TABLES `ticket_category` WRITE;
/*!40000 ALTER TABLE `ticket_category` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_product`
--

DROP TABLE IF EXISTS `ticket_product`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket_product` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket_product`
--

LOCK TABLES `ticket_product` WRITE;
/*!40000 ALTER TABLE `ticket_product` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_product` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_severity`
--

DROP TABLE IF EXISTS `ticket_severity`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket_severity` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket_severity`
--

LOCK TABLES `ticket_severity` WRITE;
/*!40000 ALTER TABLE `ticket_severity` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_severity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_state`
--

DROP TABLE IF EXISTS `ticket_state`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket_state` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL,
  `closed` int(11) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket_state`
--

LOCK TABLES `ticket_state` WRITE;
/*!40000 ALTER TABLE `ticket_state` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_state` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_status`
--

DROP TABLE IF EXISTS `ticket_status`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket_status` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_idx` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket_status`
--

LOCK TABLES `ticket_status` WRITE;
/*!40000 ALTER TABLE `ticket_status` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_type`
--

DROP TABLE IF EXISTS `ticket_type`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ticket_type` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ticket_type`
--

LOCK TABLES `ticket_type` WRITE;
/*!40000 ALTER TABLE `ticket_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `user_roles` (
  `user_id` int(11) NOT NULL,
  `role_name` varchar(45) NOT NULL,
  KEY `user_roles_user_idx` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=cp1251;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (373,'user'),(372,'admin'),(371,'admin'),(374,'user'),(375,'user'),(376,'user'),(377,'user');
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `user` varchar(80) NOT NULL default '',
  `password` varchar(80) default NULL,
  `email` varchar(128) NOT NULL default '',
  `sess_id` varchar(80) default NULL,
  `reset_id` varchar(32) default NULL,
  `login_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `reset_time` timestamp NOT NULL default '0000-00-00 00:00:00',
  `disabled` tinyint(4) default '0',
  `disabled_reason` varchar(128) default NULL,
  `ip_addr` varchar(32) default NULL,
  `security_question` varchar(128) default NULL,
  `security_answer` varchar(128) default NULL,
  `name` varchar(80) default NULL,
  `location` varchar(128) default NULL,
  `forum_default_view` tinyint(4) default '1',
  `show_email` tinyint(4) default '0',
  PRIMARY KEY  (`id`),
  KEY `sess_id` (`sess_id`)
) ENGINE=MyISAM AUTO_INCREMENT=378 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (371,'UserA','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserA@UserA.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-08-10 16:24:44','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0),(372,'UserB','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserB@UserB.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-05-22 23:09:10','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0),(373,'UserC','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserC@UserC.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-03-13 20:07:34','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0),(374,'UserD','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserD@UserD.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-08-10 16:21:28','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0),(375,'UserE','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserE@UserE.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-06-15 10:55:37','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0),(376,'UserF','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserF@UserF.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-06-16 16:46:10','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0),(377,'UserG','6221b3ce5c0d8007fedf5421f95df433742e5aee','UserG@UseerG.tld','6221b3ce5c0d8007fedf5421f95df433742e5aee',NULL,'2010-08-08 22:32:18','0000-00-00 00:00:00',0,NULL,'1.1.1.1',NULL,NULL,NULL,NULL,1,0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-09-04 22:11:59
