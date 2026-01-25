rm(list = ls())
gc()


# Ucitavanje paketa 
library(httr)
library(jsonlite)
library(purrr)
library(dplyr)
library(timeDate)
library(bizdays)
library(lubridate)

#====================================#
#====================================#
# Povlacenje podataka u JSON formatu
#====================================#
#====================================#

# Definiranje rangea datuma
date_seq <- seq(as.Date("2025-01-01"), as.Date(Sys.Date()), by = "days")

years <- 2025:year(Sys.Date())

cro_holidays <- c(
  as.Date(paste0(years, "-01-01")),  # Nova godina
  as.Date(paste0(years, "-01-06")),  # Sveta trikralja
  as.Date(paste0(years, "-05-01")),  # 1.5.
  as.Date(paste0(years, "-05-30")),  # Dan drzavnosti
  as.Date(paste0(years, "-08-05")),  # Oluja
  as.Date(paste0(years, "-08-15")),  # Velika gospa
  as.Date(paste0(years, "-11-01")),  # Svi sveti
  as.Date(paste0(years, "-11-18")),  # Dan sjecanja Vukovar
  as.Date(paste0(years, "-12-25")),  # Bozic
  as.Date(paste0(years, "-12-26")),  # sv Stjepan
  as.Date(Easter(years)),            # Uskrs
  as.Date(Easter(years) + 1)          # Uskrsnji ponedjeljak
)


date_seq_wo_week <- date_seq[!(weekdays(date_seq)) %in% c("Saturday", "Sunday")]

date_seq_wo_hol <- date_seq_wo_week[!(date_seq_wo_week) %in% cro_holidays]


date_length <- length(date_seq_wo_hol)

# Kreiranje prazne liste za punjenje
data_list <- vector(mode = "list", length = date_length)

#*** URL ***#
# "https://rest.zse.hr/web/Bvt9fe2peQ7pwpyYqODM/price-list/XZAG/2024-10-18/json"


# Skidanje podataka po datumu
n <- length(date_seq_wo_hol)
data_list <- vector("list", n)

pb <- txtProgressBar(min = 0, max = n, style = 3)

for(i in 1:length(date_seq_wo_hol)){
  date_input <- as.character(date_seq_wo_hol[i])
  url <- paste0("https://rest.zse.hr/web/Bvt9fe2peQ7pwpyYqODM/price-list/XZAG/", date_input, "/json")
  
  response <- tryCatch(GET(url, timeout(10)), error = function(e) NULL)
  
  if (is.null(response)) next
  if (status_code(response) != 200) next
  if (length(response$content) == 0) next
  
  parsed <- tryCatch(fromJSON(rawToChar(response$content)),
    error = function(e) NULL)
  
  if (is.null(parsed)) next
  

  data_list[[i]] <- response
  
  setTxtProgressBar(pb, i)
}

data_list <- Filter(Negate(is.null), data_list)

# Kreiranje prazne liste za izvlacenje prvog elementa
data_list_1st_element <- vector(mode = "list", length = length(data_list))


# Izvlacenje prvog elementa liste i transformacija content elementa iz podliste
for(i in 1:length(data_list_1st_element)) {
  data_list_1st_element[i] <- rawToChar(data_list[i][[1]]$content)
}



data_list_clean <- lapply(data_list_1st_element, fromJSON)


extract_function <- function(lst, n) {
  sapply(lst, '[', n)
}

securities_data <- extract_function(data_list_clean, 8)

segment_data <- extract_function(data_list_clean, 4)

segment_info_data <- do.call(rbind.data.frame, segment_data) %>%
  distinct(.)

# write.csv2(segment_info_data, file = "segments.csv")

rownames(segment_info_data) <- NULL

# Konacna tablica
securities_price_data <- do.call(rbind.data.frame, securities_data)

rownames(securities_price_data) <- NULL

# Brisanje pomocnih objekata
rm(data_list, data_list_1st_element, data_list_clean, securities_data, 
   date_input, date_length, date_seq, date_seq_week, date_holidays, date_seq_wo_hol, date_seq_wo_week,
   i, url, extract_function, parsed, response, cro_holidays, years)
gc()


