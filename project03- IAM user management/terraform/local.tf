locals {
  users = csvdecode(file("users.csv"))
}
#converts the csv file into a list of maps, where each map represents a user with their attributes as key-value pairs. The file function reads the contents of the users.csv file, and the csvdecode function parses the CSV data into a structured format that can be used in the Terraform configuration.

