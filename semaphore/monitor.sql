CREATE TABLE monitor(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  semid INT NOT NULL,
  otime INT,
  ctime INT NOT NULL,
  pid INT NOT NULL,
  in_proc CHAR(1) DEFAULT "N",
  cmd TEXT DEFAULT NULL,
  iteration INT NOT NULL;
);

INSERT INTO monitor(id, semid, otime, ctime, pid, in_proc, cmd, iteration) VALUES(1, 0, 1, 1, 1, "N", NULL, 0);
