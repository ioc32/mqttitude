//
//  mqttitudeLocationTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeLocationTVC.h"
#import "Location+Create.h"

@interface mqttitudeLocationTVC ()

@end

@implementation mqttitudeLocationTVC 

- (void)setFriend:(Friend *)friend
{
    _friend = friend;
    
    self.title = [friend name] ? [friend name] : friend.topic;
    
    if (friend && friend.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
        
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
        request.predicate = [NSPredicate predicateWithFormat:@"belongsTo = %@", friend];

        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:friend.managedObjectContext
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"location"];
    
    Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = location.remark ? location.remark : [NSDateFormatter localizedStringFromDate:location.timestamp
                                                                                             dateStyle:NSDateFormatterShortStyle
                                                                                             timeStyle:NSDateFormatterMediumStyle];
    cell.detailTextLabel.text = (location.placemark) ? location.placemark : [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
    if ([location.automatic boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    cell.imageView.image = location.belongsTo.image ? [UIImage imageWithData:[location.belongsTo image]] : [UIImage imageNamed:@"icon_57x57"];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    
    if (indexPath) {
        if ([segue.identifier isEqualToString:@"setLocation:"]) {
            Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
            if ([segue.destinationViewController respondsToSelector:@selector(setLocation:)]) {
                [segue.destinationViewController performSelector:@selector(setLocation:) withObject:location];
            }
        }
        if ([segue.identifier isEqualToString:@"setCenter:"]) {
            Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
            self.selectedLocation = location;
        }

    }
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Location *location = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.fetchedResultsController.managedObjectContext deleteObject:location];
    }
}

- (IBAction)addressbook:(UIBarButtonItem *)sender {
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    picker.addressBook = [Friend theABRef];
	// Display only a person's phone, email, and birthdate
	NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty],
                               [NSNumber numberWithInt:kABPersonEmailProperty],
                               [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
	
	
	picker.displayedProperties = displayedItems;
	// Show the picker
    [self presentViewController:picker animated:YES completion:nil];
    
}

#pragma ABPeoplePickerNavigationControllerDelegate
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self.friend linkToAB:person];
    [self.tableView reloadData];
    self.title = self.friend.name ? self.friend.name : self.friend.topic;
    [self dismissViewControllerAnimated:YES completion:NULL];
    return NO;
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
