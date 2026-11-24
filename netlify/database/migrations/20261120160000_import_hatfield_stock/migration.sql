-- One-time Hatfield inventory snapshot exported from Roller on 2026-10-14.
-- Quantity is available stock; blank quantities are untracked products and excluded.
-- Missing costs remain NULL. Existing matching inventory is never overwritten.
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'c48ef49f-ba0b-5a73-9a40-73bc9c358913','hat','21cm LARGE BUTTER','each',10,0,3.4900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='21cm LARGE BUTTER')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '23eabf5d-ce3e-57de-abed-45503ad4876e','hat','BAO GLITTER DUMPLING','each',72,0,1.5000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='BAO GLITTER DUMPLING')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '29b45968-a366-5c43-bf4f-ed3f419292fa','hat','BonBon Squishi','each',4,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='BonBon Squishi')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '44caebb7-cd4d-5ee1-a361-28cfb4782aa7','hat','BUTTER PUTTY','each',54,0,2.2200,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='BUTTER PUTTY')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'f43ae398-1589-561f-a915-a8be3da01c18','hat','Canvas — Free Canvas with Session','each',86,50,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Canvas — Free Canvas with Session')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'b8a659b6-42c4-5072-944b-5b520d39215e','hat','Canvas — A3 Canvas','each',200,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Canvas — A3 Canvas')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'bb2d8463-49fe-5a47-8f2a-fdc7d4375bcb','hat','Canvas — A4 Canvas','each',1000,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Canvas — A4 Canvas')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '6073c88d-16e3-5c0d-a4b2-fcd1a3803f2a','hat','Cheddar crackers — Cheddars','each',5,5,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Cheddar crackers — Cheddars')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '6f8d3f04-cc74-5282-a907-de5d11ca360c','hat','CHRISTMAS DUMPLING','each',4,0,1.9900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='CHRISTMAS DUMPLING')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'dc6fc8f5-9c79-528a-bcfa-10758c985fc7','hat','CLICKER KEY RING','each',120,0,1.4400,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='CLICKER KEY RING')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'fb40e5e1-deab-508e-b678-81d842f64151','hat','DUMPLING BASKET','each',4,0,1.9900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='DUMPLING BASKET')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'e80fe409-c5b1-5f53-b32c-b5b14f3b6f31','hat','DUMPLING CHARM SET','each',6,0,3.5800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='DUMPLING CHARM SET')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'e9d35662-1cb5-5020-997d-a9596a53af5f','hat','GOLD BIG BUTTER','each',12,0,3.9900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='GOLD BIG BUTTER')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '5712b860-0033-5e82-a709-2599fd064b33','hat','HALLOWEEN MYSTERY DUMPLIN','each',30,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='HALLOWEEN MYSTERY DUMPLIN')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '0ff7e9ab-085e-5e0a-98a5-5ef8384bd910','hat','Hello Kitty Squishy Sugar Maltose Cube','each',24,0,1.7900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Hello Kitty Squishy Sugar Maltose Cube')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '3b6e16d3-7c73-514d-bb4b-f7560f7b9823','hat','JUMBO DUMPLING','each',24,0,7.1800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='JUMBO DUMPLING')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'b2f18458-a8a9-55d0-b0a3-8b9b652f69f2','hat','JUMBO SQUEEZ RANDOM','each',54,0,4.2000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='JUMBO SQUEEZ RANDOM')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '79d642d0-f8e2-56b7-acf0-a80906756477','hat','JUMBO SQUISHY CUPCAKE','each',24,0,5.4000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='JUMBO SQUISHY CUPCAKE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '0bc1987a-7a46-5b51-b06d-5dd081f6bc51','hat','Keyrings','each',20,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Keyrings')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '64266220-1fc0-5ada-ad12-a48600a41acd','hat','MALTOSE CONTROLLER','each',6,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='MALTOSE CONTROLLER')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '51a1a711-33c4-560b-a381-e0570d6fa3f3','hat','MALTOSE JELLY DROP','each',6,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='MALTOSE JELLY DROP')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '1f73df5c-1ab2-51b7-bfb1-9c4a34e77be1','hat','MARBLE CUBE NEDO','each',78,0,2.3900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='MARBLE CUBE NEDO')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '4eb043d4-d823-5aee-bf55-8105d324bc86','hat','MARBLE JELLY FISH (ROLLER 1409595)','each',10,0,1.4900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='MARBLE JELLY FISH (ROLLER 1409595)')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'e6050c25-8644-53f9-a391-77b78a9c73b3','hat','MARBLE JELLY FISH (ROLLER 1426334)','each',54,0,1.5000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='MARBLE JELLY FISH (ROLLER 1426334)')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '5fd2875a-bc55-529b-baca-895249e44c5d','hat','Multicoloured Butter Squish','each',8,0,4.9900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Multicoloured Butter Squish')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '9de6c089-8f7b-589d-8ea7-e665f7caa6cd','hat','OREO SQUISHI','each',1,0,4.5400,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='OREO SQUISHI')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'e29ff3a2-9ae7-5693-af17-1217d157c090','hat','Paint Patch Cap — Black paint patch cap','each',4,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Paint Patch Cap — Black paint patch cap')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '8ffd6477-f439-5872-877b-89e69d45e3a8','hat','Party Bag (under 10) — Party Bag','each',23,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Party Bag (under 10) — Party Bag')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'e3063bfc-bdd1-5b21-8b16-a7f633af95c1','hat','PIZZA SLICE','each',30,0,1.5000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='PIZZA SLICE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '20883728-b4e3-5d9a-bfb2-986f44f418d6','hat','POO SUGAR MALTOSE','each',18,0,1.1800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='POO SUGAR MALTOSE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '59718cfe-bb96-5ef5-a4ea-708aa0be87ff','hat','SMALL CHEESE','each',38,0,2.1000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SMALL CHEESE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '8e083eab-b468-50b2-9847-6d69cc3acb9f','hat','SQUIDGY CHEESE','each',10,11,4.9900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SQUIDGY CHEESE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '87160847-cd2a-543c-8441-74e093bf540d','hat','SQUISH BUBBLE TEA','each',36,0,1.9800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SQUISH BUBBLE TEA')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '96dcd469-c2cc-52d2-b0df-ceeb7627fa9d','hat','SQUISH HALLOWEEN','each',36,0,1.2000,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SQUISH HALLOWEEN')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '145ee46e-b6a7-5626-9d45-f322589a4529','hat','SQUISHY EYEBALL','each',36,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SQUISHY EYEBALL')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '0bef90c5-6c0b-585c-9dde-688a122f69be','hat','SUGAR AXOLOTL','each',12,0,1.9800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SUGAR AXOLOTL')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '4437916d-45c1-5e1e-b6ab-6df52ba8113a','hat','SUGAR MALTOSE CAKE','each',24,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SUGAR MALTOSE CAKE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '2efed4b5-6db0-5bcd-8e87-5ba8c713e818','hat','SUGAR MALTOSE KITTIES — SUGAR KITTIES','each',12,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SUGAR MALTOSE KITTIES — SUGAR KITTIES')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '8a6daf5b-c87c-5264-874a-dfa02d22cf12','hat','SUGAR SPLAT','each',8,0,1.9900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SUGAR SPLAT')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '30e37af1-100b-5cb3-b740-368736e23866','hat','SUPER BUTTER BLOCK','each',8,0,3.4900,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='SUPER BUTTER BLOCK')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'efcebfaa-cf71-52cf-bb0d-52960a355044','hat','Tshirt','each',0,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Tshirt')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT 'f0f6f4f7-3d23-550a-97b3-814836134af6','hat','Water — Bottled Water','each',-10,0,NULL,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='Water — Bottled Water')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '9dfc3547-0130-53b6-84cb-fd9511927bac','hat','XMAS BEANIE PALS','each',6,0,2.5500,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='XMAS BEANIE PALS')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '54e9d7a6-662e-5055-9285-9efcbc915c69','hat','XMAS BUTTER SLIME','each',48,0,1.7800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='XMAS BUTTER SLIME')
ON CONFLICT (id) DO NOTHING;
INSERT INTO hq_stock (id,venue_id,item,unit,level,min_level,unit_cost,on_order)
SELECT '278a4f35-201b-5f53-ab28-dc6884383f4f','hat','XMAS GLITTER SURPRISE','each',38,0,2.3800,false
WHERE NOT EXISTS (SELECT 1 FROM hq_stock WHERE venue_id='hat' AND item='XMAS GLITTER SURPRISE')
ON CONFLICT (id) DO NOTHING;
