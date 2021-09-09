exec sp_msforeachtable 'DENY ALTER, DELETE, INSERT, UPDATE, SELECT ON ? TO [site]'
DENY SELECT ON SCHEMA::[dbo] TO [site]
GRANT ALTER, DELETE, INSERT, UPDATE ON [dbo].Payments TO [site] AS [dbo]