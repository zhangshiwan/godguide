Meteor.methods
	registerUser: (formData) ->

		check formData, Object

		if RocketChat.settings.get('Accounts_RegistrationForm') is 'Disabled'
			throw new Meteor.Error 'error-user-registration-disabled', 'User registration is disabled', { method: 'registerUser' }

		else if RocketChat.settings.get('Accounts_RegistrationForm') is 'Secret URL' and (not formData.secretURL or formData.secretURL isnt RocketChat.settings.get('Accounts_RegistrationForm_SecretURL'))
			throw new Meteor.Error 'error-user-registration-secret', 'User registration is only allowed via Secret URL', { method: 'registerUser' }

		RocketChat.validateEmailDomain(formData.email);

		userData =
			email: s.trim(formData.email.toLowerCase())
			password: formData.pass

		# Check if user has already been imported and never logged in. If so, set password and let it through
		importedUser = RocketChat.models.Users.findOneByEmailAddress s.trim(formData.email.toLowerCase())
		if importedUser?.importIds?.length and !importedUser.lastLogin
			Accounts.setPassword(importedUser._id, userData.password)
			userId = importedUser._id
		else
			userId = Accounts.createUser userData

		RocketChat.models.Users.setName userId, s.trim(formData.name)

		RocketChat.saveCustomFields(userId, formData)



		try
			if userData.email
				Accounts.sendVerificationEmail(userId, userData.email);


			mysqluserData = {"username":s.trim(formData.name),"password":formData.pass,"email":userData.email}

			mysqluserDataObj =
				username:s.trim(formData.name)
				password:formData.pass
				email:userData.email

			console.log('mysqluserData is', mysqluserData)

#			HTTP.post "http://localhost:8080/sys/user/save", mysqluserDataObj, (error, response) ->
#				if response?.statusCode is 200
#					console.log('insert mysql user success', "")
#					return
#				if error
#					console.log('insert mysql user fail', error)
#					return
#
#				if not error?
#					return

#			 options =
#				 headers:{'Content-Type': 'application/json'},
#				 data: mysqluserData

			response = undefined
			try
				response = HTTP.post "http://localhost:8080/sys/user/save",
#					auth: config.clientId + ':' + OAuth.openSecret(config.secret)
					headers:
						Accept: 'application/json'
						'Content-Type': 'application/json;charset=UTF-8'
#						'User-Agent': @userAgent
					data:mysqluserData


					console.log('insert mysql user response', response)

			catch err
				console.log('insert mysql user fail', err)






			console.log('insert mysql user2 response', response)






		catch error
			# throw new Meteor.Error 'error-email-send-failed', 'Error trying to send email: ' + error.message, { method: 'registerUser', message: error.message }



		return userId
