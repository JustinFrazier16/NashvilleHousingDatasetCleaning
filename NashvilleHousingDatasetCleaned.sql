/*
Cleaning Nashville Housing Dataset
*/

-- Convert SaleDate col to Date

Select
	SaleDate,
    str_to_date(SaleDate, '%M %d, %Y') as UpdatedSaleDate
From
	nashville_housing_database.sheet1
    
-- Update Dataset to convert SaleDate col to Date

Update nashville_housing_database.sheet1
Set SaleDate = str_to_date(SaleDate, '%M %d, %Y') 

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

-- - Checking Property Addresses for NULL values 
Select
	ParcelID
From
	nashville_housing_database.sheet1
Where
	PropertyAddress is NULL 
    
-- - Converting Property Address NULLS with proper addresses
Select
	a.UniqueID,
    b.UniqueID,
	a.ParcelID, 
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IFNULL(a.PropertyAddress,b.PropertyAddress)
From
	nashville_housing_database.sheet1 a
JOIN nashville_housing_database.sheet1 b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID 
Where
	a.PropertyAddress is NULL
    
-- - Updating Property Address NULLS with proper addresses
Update nashville_housing_database.sheet1 as a
LEFT JOIN nashville_housing_database.sheet1 as b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID 
Set a.PropertyAddress = IFNULL(a.PropertyAddress,b.PropertyAddress)
Where
	a.PropertyAddress is NULL
    
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Invididual Colums (Address, City, State)

-- - Analyzing Property addresses for Clean-Up 
Select
	PropertyAddress
From 
	nashville_housing_database.sheet1

-- - Breaking PropertyAddress into Address and State
Select
	PropertyAddress,
	SUBSTRING_INDEX(PropertyAddress,',',1) as Address,
    SUBSTRING_INDEX(PropertyAddress,',',-1) as City
From 
	nashville_housing_database.sheet1
    
-- - Making new colums for Address and State
-- Column for Address
Alter Table
	nashville_housing_database.sheet1
Add 
	SplitPropertyAddress varchar(255)
    
    
Update 
	nashville_housing_database.sheet1
SET 

	SplitPropertyAddress = SUBSTRING_INDEX(PropertyAddress,',',1)

-- Column for City
Alter Table
	nashville_housing_database.sheet1
Add 
	SplitPropertyCity varchar(255)
    
    
Update 
	nashville_housing_database.sheet1
SET 
	SplitPropertyCity = SUBSTRING_INDEX(PropertyAddress,',',-1)
    
-- - Analyzing Owner addresses for Clean-Up 
Select
	OwnerAddress
From 
	nashville_housing_database.sheet1
    
-- - Breaking OwnerAddress into Address, City, and State

Select
	SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
   If(  length(OwnerAddress) - length(replace(OwnerAddress, ' ', ''))>1,  
       SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) ,NULL) 
           as City,
   SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
From 
	nashville_housing_database.sheet1
    
-- - Making new colums for Address, City, and State
-- Column for Owner City
Alter Table
	nashville_housing_database.sheet1
Add 
	SplitOwnerCity varchar(255)
    
Update 
	nashville_housing_database.sheet1
SET 
	SplitOwnerCity = If(  length(OwnerAddress) - length(replace(OwnerAddress, ' ', ''))>1,  
       SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) ,NULL)
       
-- Column for Owner Address
Alter Table
	nashville_housing_database.sheet1
Add 
	SplitOwnerAddress varchar(255)
    
Update 
	nashville_housing_database.sheet1
SET 
	SplitOwnerAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1)
    
-- Column for Owner State
Alter Table
	nashville_housing_database.sheet1
Add 
	SplitOwnerState varchar(255)
    
Update 
	nashville_housing_database.sheet1
SET 
	SplitOwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1)
    
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in Sold as Vacant field

-- - Analyze SoldAsVacant for Y and N
Select 
	SoldAsVacant,
    Case 
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end
From 
	nashville_housing_database.sheet1

-- - Convert Y and N to Yes and No in SoldAsVacant
Update 
	nashville_housing_database.sheet1
SET SoldAsVacant = 
	Case 
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end
    
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
With RowNum AS 
(
	Select 
		*,
		Row_Number() Over (
		Partition by 

			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			Order by
				UniqueID 
				) row_num
	From 
		nashville_housing_database.sheet1
)
Delete
From
 nashville_housing_database.sheet1 USING nashville_housing_database.sheet1 Join RowNum on nashville_housing_database.sheet1.UniqueID = RowNum.UniqueID
Where
 RowNum.row_num > 1
