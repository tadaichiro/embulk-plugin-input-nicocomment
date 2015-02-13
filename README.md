# Embulk input plugin for niconico comment 

extract niconico douga ranking comment
extract data are id , comment, datetime

program has 5-30 sec. waitime , so processing time is very long

## Configuration

- **id** niconico douga id (string)
- **password** niconico douga password (string)
- **target** ranking target. candidate value is fav, view, res, monthly, mylist(string, default:fav)
- **term** ranking term. candidate value is hourly, daily, weekly, monthly, total(string, default:hourly)
- **category** ranking category.(string, default:all)

### Example

```yaml
in:
  type: nicocomment
  id: mailaddress
  password: password
```