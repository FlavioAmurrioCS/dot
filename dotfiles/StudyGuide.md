

**Good Software Characteristics:**

```
1. Correct
2. Scalable
3. Available
4. Secure
5. Sound
6. Interoperable
```
**Reasons for Software Reuse:**

```
1. Design, implementation and testing are expensive
2. Maintenance is expensive
```
**Structure-Oriented Software Development:**

```
Reusable Unit is a Module
Depends on specific technology and operating environment
Reusable function library
```
**Object-Oriented Software Development:**

```
Reusable Unit is a Class
Depends on specific technology and operating environment
Reusable class library or design pattern
```
**Middleware-Oriented Software Development:**

```
Reusable Unit is a Class
Less dependent on specific technology and operating environment
Reusable middleware
```
**Component-Based Software Development:**

```
Reusable Unit is a Component
No dependency on specific technology or operating environment
Reusable components
```
**Component-Based Software:**

```
Assembly of software components that conform to component-based software engineering principles
```
**Characteristics of a Reusable Component:**

```
1. Documented
2. Tested
3. Input validation checking
4. Meaningful error messages
5. Not dependent on an environment
6. Does not know how it will be used
```
**3 Flavors of Code:**

```
1. Core Concerns
2. Cross Cutting Concerns
3. Plumbing
```
**Core Concerns:**

```
Functions of an application that satisfy the business requirements
```
**Cross Cutting Concerns:**

```
Secondary operations required to keep the primary functions running correctly and efficiently
```
**Plumbing:**

```
Integration aspects, for getting data and invocation from point A to point B
```
**Efficient Software Development:**

```
Develop core concerns and reuse capabilities for cross cutting concerns and plumbing
```
**JavaServer Faces (JSF):**

```
MVC-based Web Development framework that helps build HTML forms, validate form values, invoke business logic, and display results
```
**Separation of Concerns:**

```
Separates the presentation, business logic, and data

Promotes maintainability, scalability, and availability of software systems
```
**Pros of Web Apps:**

```
1. Universal access
2. Automatic "updates" meaning content is never out of date
```
**Cons of Web Apps:**

```
1. Poor GUI
2. Inefficient communication
```
**Facelet:**

```
View component in JSF 2.0 that promotes code reuse and extension via templating and composition features

Rendered in a web browser but executed in the web container
```
**ManagedBean:**

```
Class used to represent Form data in JSF that is automatically managed by the framework
```
**Expression Language:**

```
Language used to access or set a managed bean's properties and methods
```
**JSF MVC Controller:**

```
FacesServlet

Processes each requested JSF page so that the server can return a response to the client
```
**JSF MVC Model:**

```
ManagedBean - contains all application data
```
**JSF MVC View:**

```
Facelet - presents the data stored in the model
```
**<h:panelGrid column="3">:**

```
Short cut to create table effect

Each element within panelGrid becomes a column
```
**2 Ways to Declare ManagedBean:**

```
1. Add @ManagedBean before class declaration (request scoped by default)
2. Define <managed-bean> in faces-config.xml
```
**ManagedBean Initialization:**

```
1. Initialize with zero-arg constructor
2. Lifecycle defined by scope
3. Call Setter methods
4. Call Getter methods
```
**3 Parts of ManagedBean:**

```
1. Bean Properties (getter/setter methods)
2. Action controller methods
3. Placeholders for results data
```
**Navigation Rule Structure:**

```
1. One navigation-rule per form with a single from-view-id
2. Each navigation-rule can have many navigation-cases
```
**#{...}:**

```
Indicates the expression is a JSF Expression Language (EL) expression
```
**Accessing ManagedBean Properties with EL:**

```
Faces Servelet invokes Set or Get method based on context in which the property is used
```
**Default ManagedBean Scope:**

```
Request Scope
```
**ManagedBean Instantiation:**

```
ManagedBean is instantiated twice; once when the form is initially displayed and again when the form is submitted
```
**Basic JavaBean Conventions:**

```
1. Zero arg constructor
2. No public instance variables
3. Use getBlah/setBlah or isBlah/setBlah naming conventions
```
**ManagedBean Parts: Bean Properties:**

```
1. One pair of getter and setter for each input element
2. Setter methods called before action controller method when form is submitted.
```
**ManagedBean Parts: Action Controller Methods:**

```
1. Generally one method per button
2. Method is called when button is pressed that is assigned to the action controller method
```
**ManagedBean Parts: Placeholders for Results Data:**

```
1. Not automatically called by JSF; instead filled by action controller method
2. Requires a getter method in order for values to be output to page, but does not require a setter method
```
**Bean Scope:**

```
Determines how long managed beans will stay "alive" and which users and requests can access previous bean instances
```
**Request Scope:**

```
A new instance of the bean is created for every HTTP request (default scope)

@RequestScoped
```
**Application Scope:**

```
A new instance of the bean is instantiated the first time any page with that bean name is accessed

Different users and different pages will use same instance as long as web app is running

@ApplicationScoped
```
**Session Scope:**

```
A new instance of the bean is instantiated the first time any page with that bean name is accessed by a particular user

Bean should be Serializable so that session data can live across server restarts

@SessionScoped
```
**Types of Bean Scope:**

```
1. Request
2. Application
3. Session
4. View
5. Flow
6. Custom
7. None
```
**View Scope:**

```
Same bean instance is used as long as user is on same page
```
**Flow Scope:**

```
Same bean instance is used as long as it is same user on same set of pages
```
**Custom Scope:**

```
Bean is stored in Map and programmer controls lifecycle of bean
```
**None Scope:**

```
Bean is not placed in a scope. Useful for beans that are referenced by other beans that are in scopes.
```
**Navigation Rules Syntax:**

```
<navigation-rule>
 <from-view-id>/page.xhtml</from-view-id>
 <navigation-case>
 <from-outcome>return-value-1</from-outcome>
 <to-view-id>/result-page-1.xhtml</to-view-id>
 </navigation-case>
</navigation-rule>
```
**Pros of Explicit Navigation Mappings:**

```
1. Provides a better understanding of the project
2. Provides more flexibility allowing use of wildcards
```
**Cons of Explicit Navigation Mappings:**

```
1. Simpler to start with default mappings (return values=pages)
2. Redundant if return values are 1-to-1 to results pages (i.e. only 1 navigation option)
```
**Requirements of Explicit ManagedBean Declaration:**

```
1. Must define bean name explicitly
2. Must define bean scope explicitly
3. Must define bean class explicitly
```
**Pros of Explicit ManagedBean Declaration:**

```
1. Better understanding of beans used in project
2. Multiple instances of same bean in same page
3. Same class in multiple pages with multiple scopes
```
**Cons of Explicit ManagedBean Declaration:**

```
More work than using @ManagedBean
```
**Pros of Expression Language:**

```
1. Shorthand notation for bean properties
2. Access to collection elements
3. Predefined variables (implicit objects)
4. Passing arguments
5. Empty values instead of error messages
```
**3 Uses of #{...}:**

```
1. Output value
2. Submitted value
3. Method call after submission
```
**JSF Constructs for Handling Variable-Length Data:**

```
1. h:dataTable (simplest for page author)
2. ui:repeat (most control for page author)
```
**Need for Validation:**

```
1. Check required fields and format
2. Redisplay form for missing or bad values
```
**How To Do Manual Validation:**

```
1. Setter methods take strings only
2. Action controller checks values
3. Store error messages using FacesContext.addMessage
4. Return null to redisplay form
```
**How To Create Error Messages:**

```
1. FacesContext.getCurrentInstance();
2. new FacesMessage("some warning");
3.
// add a message to form as a whole
context.addMessage(null, facesMessage);

or

// add a message to specific element
context.addMessage("someId", facesMessage);
```
**Action Controller Validation (Manual Validation):**

```
1. Use when validation is tied to business logic
2. Use when need to validate based on multiple fields
```
**Type Conversion Validation (Implicit Automatic Validation):**

```
Use when need to validate type of various input fields
```
**How To Do Implicit Automatic Validation:**

```
1. Define bean properties to be simple standard types
2. System attempts to convert types automatically and redisplays form if conversion error with error message (converterMessage)
3. Define required fields on form with required="true" (requiredMessage)
```
**Precedence of Validity Tests:**

```
1. Required
2. Type Conversion
3. Validator Rules

Can bypass validation by setting immediate="true"

JSF Validator Tags```
**(Explicit Automatic Validation):**

```
1. Use when not tied to business logic
2. Use to check values are within range or length
```
**How To Do Explicit Automatic Validation:**

```
1. Define bean properties to be simple types
2. Add f:validate... or f:convert...
3. System checks validity after checking required and type (validatorMessage)

Custom Validator Me```thods
**(Custom Validation):**

```
1. Use if checking one field at a time
2. Use to create tests not built into JSF validator tags
```
**How To Do Custom Validation:**

```
1. Add validator="#{someBean.someMethod}" to Facelet
2. Throw ValidatorException with a FacesMessage in ManagedBean if validation fails

public void validateAmount(FacesContext context, UIComponent component, Object value) throws ValidatorException {
 checkTheValue(value);
 FacesMessage message = new FacesMessage("");
 throw new ValidatorException(message);
}

Do not use f:validate... with a custom validator on same field
```
**h:dataTable Implementation:**

```
<h:dataTable var="item" value="#{bean.collection}"
 styleClass="tableStyle"
 headerClass="headerStyle"
 rowClasses="even, odd">
 <h:column>
 <f:facet name="header">Prop</f:facet>
 #{item.prop}
 </h:column>
</h:dataTable>
```
**ui:repeat Implementation:**

```
<ul>
 <ui:repeat var="item" value="#{bean.collection}" varStatus="status">
 <ui:fragment rendered="#{status.even}">
 <li>#{item.prop}</li>
 <h: outputText value="and" rendered="#{!status.last}"/>
 </ui:fragment>
 </ui:repeat>
</ul>
```
**Pros of JSF Specific Ajax:**

```
1. Can update JSF elements on client
2. No JavaScript
3. Ajax calls know about JSF managed beans on server
4. No servlets or parsing parameters on server
```
**f:ajax Implementation:**

```
<h:commandButton ... action="#{someBean.action}">
 <f:ajax render="id1 id2" execute="id3 id4"
 event="keyup" onevent="jsHandler"/>
</h:commandButton>

render - the elements to redisplay on the page
execute - the elements to send to the server to process
event - the DOM event to respond to
onevent - the JavaScript function to run when event fired
```
**f:ajax with action:**

```
<h:commandButton value="Get Value"
 action="#{bean.action}">
 <f:ajax render="id1"/>
</h:commandButton>
<h:outputText value="#{bean.value}"
 id="id1"/>

public double getValue() { return(value); }

public String action() {
 value = Math.random();
 return(null);
 }
```
**f:ajax with no action:**

```
<h:commandButton value="Get Value"
 action="nothing">
 <f:ajax render="id1"/>
</h:commandButton>
<h:outputText value="#{bean.value}"
 id="id1"/>

public double getValue() {
 return(Math.random());
}
```
**<f:ajax execute="@form" render="someId"/>:**

```
Send all elements of current form to server to process
```
**PrimeFaces Spinner and Calendar Components:**

```
1. Convert types automatically
2. Do not require validatorMessage because component will not permit the user to enter an illegal type

<p:spinner value="#{someBean.someNumber}"/>
<p:calendar value="#{someBean.someDate}"/>
```
**PrimeFaces AutoComplete:**

```
<p:autoComplete value="#{someBean.someString}"
 completeMethod="#{someBean.collection}"
 required="true"
 requiredMessage="..."
 queryDelay="1000"
 minQueryLength="3"/>
```
**PrimeFaces InputMask:**

```
<p:inputMask mask="aaa-999-a999"
 value="#{someBean.someKey}"
 required="true"
 id="key"
 requiredMessage="..."/>
<p:message for="key"/>

a - any letter
9 - any number
* - any letter or number
```
**Enterprise JavaBeans (EJB):**

```
Framework for component-based distributed computing where the developer writes Java classes (EJBs) that implement all of the required business logic
```
**EJB Model Services:**

```
1. Lifecycle
2. State Management
3. Security
4. Transactions
5. Persistence
```
**EJB JavaBean Types:**

```
1. Sessions Beans
2. Java Persistence API (JPA)
3. Message Driven Beans
```
**Session Beans:**

```
Task-oriented; model business process, non-persistence states, and may access data directly
```
**3 Types of Session Beans:**

```
1. Stateless
2. Stateful
3. Singleton
```
**Message Driven Beans:**

```
Model business logic involved with asynchronous messages

Asynchronously invoked to handle the processing of incoming JMS messages
```
**Reasons for using EJB:**

```
1. Scalability
2. Transaction
3. Security
4. Remote business logic
```
**EJB Remote Interface:**

```
Defines what business methods the bean is to expose to the client

@Remote
public interface SomeInterface { }
```
**EJB Bean Implementation Class:**

```
Contains all implementation details of the business logic

Type of bean determines what interface the implementation class will implement (i.e. Stateless, Stateful, Singleton)

@Stateless
public class SomeClass implements SomeInterface { }
```
**EJB Client Implementation:**

```
1. Obtain reference to JNDI server
2. Obtain reference to remote object
3. Invoke method on the bean
