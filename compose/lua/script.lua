if sysbench.cmdline.command == nil then
  error("Command is required. Supported commands: run")
end

sysbench.cmdline.options = {
  point_selects = {"Number of point SELECT queries to run", 5},
  skip_trx = {"Do not use BEGIN/COMMIT; Use global auto_commit value", true}
}

local page_types = { "actor", "character", "movie" }
local select_counts = {
  "SELECT COUNT(*) FROM imdb.name",
  "SELECT COUNT(*) FROM imdb.users",
  "SELECT COUNT(*) FROM imdb.title"
}
local select_points = {
  "SELECT * FROM imdb.title WHERE id = %d",
  "SELECT * FROM imdb.name WHERE id = %d",
  "SELECT * FROM imdb.char_name WHERE id = %d",
  "SELECT * FROM imdb.comments ORDER BY id DESC limit 10",
  "SELECT * FROM imdb.comments WHERE type='movie' AND type_id = 473215 ORDER BY id DESC",
  "SELECT * FROM imdb.favorites WHERE user_id = %d AND type='actor'",
  "SELECT * FROM imdb.favorites WHERE user_id = %d AND type='movie'",
  "SELECT * FROM imdb.person_info WHERE person_id = %d",
  "SELECT * FROM imdb.movie_info WHERE movie_id = %d",
  "SELECT AVG(rating) avg FROM imdb.movie_ratings WHERE movie_id = %d",
  "SELECT user2 FROM imdb.user_friends WHERE user1 = %d",
  "SELECT * FROM imdb.cast_info WHERE movie_id = %d AND role_id = 1 ORDER BY nr_order ASC",
  "SELECT * FROM imdb.users WHERE id = %d",
  "SELECT * FROM imdb.users ORDER BY RAND() LIMIT 1",
  "SELECT * FROM imdb.users WHERE last_login_date > NOW() - INTERVAL 10 MINUTE ORDER BY last_login_date DESC LIMIT 10",
  "SELECT DISTINCT type, viewed_id, id FROM imdb.page_views ORDER BY id DESC LIMIT 5"
}
local select_string = {
  "SELECT * FROM imdb.title WHERE title LIKE '%s%%'"
}
local inserts = {
  "INSERT INTO imdb.users (email_address, first_name, last_name) VALUES ('%s', '%s', '%s')",
  "INSERT INTO imdb.page_views (type, viewed_id, user_id) VALUES ('%s', %d, %d)"
}


function execute_selects()
  for i, o in ipairs(select_counts) do
    con:query(o)
  end

  -- loop for however many the user wants to execute
  for i = 1, sysbench.opt.point_selects do

    -- select random query from list
    local randQuery = select_points[math.random(#select_points)]

    -- generate random ids and execute
    local id = sysbench.rand.pareto(1, 3000000)
    con:query(string.format(randQuery, id))
  end

  -- generate random string
  for i, o in ipairs(select_string) do
    local str = sysbench.rand.string(string.rep("@", sysbench.rand.special(2, 15)))
    con:query(string.format(o, str))
  end
end


function create_random_email()
  local username = sysbench.rand.string(string.rep("@",sysbench.rand.uniform(5,10)))
  local domain = sysbench.rand.string(string.rep("@",sysbench.rand.uniform(5,10)))
  return username .. "@" .. domain .. ".com"
end


function execute_inserts()
  -- generate fake email/info
  local email = create_random_email()
  local firstname = sysbench.rand.string("first-" .. string.rep("@", sysbench.rand.special(2, 15)))
  local lastname = sysbench.rand.string("last-" .. string.rep("@", sysbench.rand.special(2, 15)))

  -- INSERT for new imdb.user
  con:query(string.format(inserts[1], email, firstname, lastname))

  -- INSERT for imdb.page_view
  local page = page_types[math.random(#page_types)]
  con:query(string.format(inserts[2], page, sysbench.rand.special(2, 500000), sysbench.rand.special(2, 500000)))
end


-- Called by sysbench to initialize script
function thread_init()
  drv = sysbench.sql.driver()
  con = drv:connect()
end


-- Called by sysbench when tests are done
function thread_done()
  con:disconnect()
end


-- Called by sysbench for each execution
function event()
  if not sysbench.opt.skip_trx then
   con:query("BEGIN")
  end

  execute_selects()
  execute_inserts()

  if not sysbench.opt.skip_trx then
   con:query("COMMIT")
  end
end
